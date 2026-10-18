"""Genera las graficas de rendimiento del informe a partir de los resultados.

Uso (desde load-tests/, despues de scripts/cloudwatch.py):
    python scripts/graficas.py

Salida en graficas/:
    escalabilidad-latencia.png     latencia promedio / P95 / P99 por numero de usuarios
    escalabilidad-throughput.png   requests por segundo por numero de usuarios
    escalabilidad-errores.png      tasa de errores por numero de usuarios (umbral 5 %)
    serie-<escenario>.png          requests/s y P95 a lo largo de cada prueba (k6)
    recuperacion-sqs.png           vaciado de la cola despues de cortar la carga
    tabla-resultados.md            tabla con todas las metricas por escenario
"""

import csv
import gzip
import json
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.ticker import FuncFormatter  # noqa: E402

RAIZ = Path(__file__).resolve().parent.parent
RESULTADOS = RAIZ / "results"
SALIDA = RAIZ / "graficas"

# Paleta categorica validada (slots 1-3, modo claro) y tokens de texto/superficie.
AZUL, NARANJA, AQUA = "#2a78d6", "#eb6834", "#1baf7a"
SUPERFICIE, TEXTO, TEXTO_2, GRILLA = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
CRITICO = "#d03b3b"

plt.rcParams.update(
    {
        "figure.facecolor": SUPERFICIE,
        "axes.facecolor": SUPERFICIE,
        "axes.edgecolor": GRILLA,
        "axes.labelcolor": TEXTO_2,
        "axes.titlecolor": TEXTO,
        "axes.titlesize": 13,
        "axes.titleweight": "bold",
        "axes.titlelocation": "left",
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.grid": True,
        "axes.axisbelow": True,
        "grid.color": GRILLA,
        "grid.linewidth": 0.8,
        "xtick.color": TEXTO_2,
        "ytick.color": TEXTO_2,
        "legend.frameon": False,
        "legend.labelcolor": TEXTO,
        "font.size": 10,
        "lines.linewidth": 2,
        "lines.markersize": 7,
        "savefig.dpi": 150,
        "savefig.bbox": "tight",
    }
)


def leer(ruta):
    return json.loads(Path(ruta).read_text(encoding="utf-8-sig"))


def escenarios(prefijo):
    """metricas.json de las carpetas que empiezan con el prefijo, ordenadas por VUs."""
    datos = [leer(f) for f in RESULTADOS.glob(f"{prefijo}*/metricas.json") if "pc-local" not in str(f)]
    return sorted(datos, key=lambda m: m["vus"])


def percentil(valores, p):
    return valores[min(len(valores) - 1, int(round(p / 100 * (len(valores) - 1))))] if valores else 0


def desglose(escenario):
    """Separa respuestas exitosas (2xx) de rechazadas a partir del CSV crudo de k6.

    El promedio global de k6 mezcla los 503 de throttling (muy rapidos) con las
    respuestas reales; para analizar la latencia se usan solo las exitosas.
    """
    archivo = RESULTADOS / escenario / "serie.csv.gz"
    cache = RESULTADOS / escenario / "desglose.json"
    if cache.exists():
        return leer(cache)
    if not archivo.exists():
        return None
    ok, codigos = [], defaultdict(int)
    with gzip.open(archivo, "rt", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["metric_name"] != "http_req_duration" or "notifications" not in r.get("name", ""):
                continue
            codigos[r["status"]] += 1
            if r["status"].startswith("2"):
                ok.append(float(r["metric_value"]))
    ok.sort()
    total = sum(codigos.values())
    d = {
        "codigos_http": dict(codigos),
        "exitosas": len(ok),
        "rechazadas": total - len(ok),
        "latencia_exitosas_ms": {
            "promedio": sum(ok) / len(ok) if ok else 0,
            "minimo": ok[0] if ok else 0,
            "maximo": ok[-1] if ok else 0,
            "p95": percentil(ok, 95),
            "p99": percentil(ok, 99),
        },
    }
    cache.write_text(json.dumps(d, indent=2), encoding="utf-8")
    return d


def etiqueta_final(ax, x, y, texto, color):
    ax.annotate(texto, (x, y), xytext=(6, 0), textcoords="offset points", va="center", color=TEXTO, fontsize=9)
    ax.plot([], [], color=color)


def grafica_latencia(datos, nombre, titulo):
    """Latencia de las respuestas exitosas (202) por nivel de usuarios."""
    vus = [str(m["vus"]) for m in datos]
    x = range(len(datos))
    lat = [(desglose(m["escenario"]) or {}).get("latencia_exitosas_ms") or m["latencia_ms"] for m in datos]
    fig, ax = plt.subplots(figsize=(8, 4.5))
    maximo = 0
    for clave, etiqueta, color in (("promedio", "Promedio", AZUL), ("p95", "P95", NARANJA), ("p99", "P99", AQUA)):
        ys = [l[clave] for l in lat]
        maximo = max(maximo, *ys)
        ax.plot(x, ys, marker="o", color=color, label=etiqueta, markeredgecolor=SUPERFICIE, markeredgewidth=2)
    for i, l in enumerate(lat):
        ax.annotate(f"{l['p99']:,.0f}", (i, l["p99"]), xytext=(0, 8), textcoords="offset points", ha="center",
                    color=TEXTO, fontsize=9)
    if maximo > 2500:
        ax.axhline(5000, color=CRITICO, linewidth=1, linestyle="--")
        ax.annotate("Limite 5 s", (0, 5000), xytext=(0, 4), textcoords="offset points", color=TEXTO_2, fontsize=9)
    ax.set_xticks(list(x), vus)
    ax.set_xlabel("Usuarios virtuales concurrentes")
    ax.set_ylabel("Tiempo de respuesta (ms)")
    ax.set_ylim(0, maximo * 1.3)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}"))
    ax.set_title(titulo + " (solo respuestas exitosas)")
    ax.legend(loc="lower right", ncol=3)
    fig.savefig(SALIDA / nombre)
    plt.close(fig)


def grafica_throughput(datos, nombre, titulo):
    """Requests/s apilados: exitosas (202) y rechazadas (503 por throttling)."""
    vus = [str(m["vus"]) for m in datos]
    exit_rps, rech_rps = [], []
    for m in datos:
        d = desglose(m["escenario"])
        dur = m["requests"] / m["throughput_rps"] if m["throughput_rps"] else 1
        exit_rps.append((d["exitosas"] if d else m["requests"] * (1 - m["tasa_errores"])) / dur)
        rech_rps.append((d["rechazadas"] if d else m["requests"] * m["tasa_errores"]) / dur)
    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.bar(vus, exit_rps, color=AZUL, width=0.55, edgecolor=SUPERFICIE, linewidth=2, label="Exitosas (202)")
    ax.bar(vus, rech_rps, bottom=exit_rps, color=NARANJA, width=0.55, edgecolor=SUPERFICIE, linewidth=2,
           label="Rechazadas (503 por throttling)")
    for i, (e, r) in enumerate(zip(exit_rps, rech_rps)):
        ax.annotate(f"{e:,.0f} ok/s", (i, e / 2), ha="center", va="center", color="white", fontsize=9, fontweight="bold")
        ax.annotate(f"{e + r:,.0f}", (i, e + r), xytext=(0, 4), textcoords="offset points", ha="center",
                    color=TEXTO, fontsize=9)
    ax.grid(axis="x", visible=False)
    ax.set_xlabel("Usuarios virtuales concurrentes")
    ax.set_ylabel("Requests por segundo")
    ax.set_ylim(0, max(e + r for e, r in zip(exit_rps, rech_rps)) * 1.15)
    ax.set_title(titulo)
    ax.legend(loc="upper left")
    fig.savefig(SALIDA / nombre)
    plt.close(fig)


def grafica_barras(datos, clave, nombre, titulo, eje_y, formato, umbral=None):
    vus = [str(m["vus"]) for m in datos]
    ys = [clave(m) for m in datos]
    fig, ax = plt.subplots(figsize=(8, 4.5))
    barras = ax.bar(vus, ys, color=AZUL, width=0.55, edgecolor=SUPERFICIE, linewidth=2)
    for b, y in zip(barras, ys):
        ax.annotate(formato(y), (b.get_x() + b.get_width() / 2, y), xytext=(0, 4), textcoords="offset points",
                    ha="center", color=TEXTO, fontsize=9)
    if umbral is not None:
        ax.axhline(umbral, color=CRITICO, linewidth=1, linestyle="--")
        ax.annotate(f"Umbral {formato(umbral)}", (0, umbral), xytext=(-20, 4), textcoords="offset points",
                    color=TEXTO_2, fontsize=9)
    ax.grid(axis="x", visible=False)
    ax.set_xlabel("Usuarios virtuales concurrentes")
    ax.set_ylabel(eje_y)
    ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: formato(v)))
    ax.set_ylim(top=max(ys + [umbral or 0]) * 1.15 or 1)
    ax.set_title(titulo)
    fig.savefig(SALIDA / nombre)
    plt.close(fig)


def serie_temporal(carpeta, bin_s=5):
    """requests/s, P95 y % de errores por intervalo a partir del CSV crudo de k6."""
    archivo = carpeta / "serie.csv.gz"
    if not archivo.exists():
        return None
    duraciones, fallidos = defaultdict(list), defaultdict(int)
    with gzip.open(archivo, "rt", encoding="utf-8") as f:
        for r in csv.DictReader(f):
            if r["metric_name"] != "http_req_duration" or "notifications" not in r.get("name", ""):
                continue
            t = int(r["timestamp"]) // bin_s * bin_s
            duraciones[t].append(float(r["metric_value"]))
            if not r["status"].startswith("2"):
                fallidos[t] += 1
    if not duraciones:
        return None
    t0 = min(duraciones)
    filas = []
    for t in sorted(duraciones):
        d = sorted(duraciones[t])
        filas.append((t - t0, len(d) / bin_s, d[int(0.95 * (len(d) - 1))], 100 * fallidos[t] / len(d)))
    return filas


def grafica_serie(carpeta):
    filas = serie_temporal(carpeta)
    if not filas:
        return
    t = [f[0] for f in filas]
    fig, (a1, a2, a3) = plt.subplots(3, 1, figsize=(9, 7.5), sharex=True)
    a1.plot(t, [f[1] for f in filas], color=AZUL)
    a1.set_ylabel("Requests/s")
    a1.set_title(f"{carpeta.name}: throughput, P95 y errores durante la prueba")
    a2.plot(t, [f[2] for f in filas], color=NARANJA)
    a2.set_ylabel("P95 (ms)")
    a2.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}"))
    a3.plot(t, [f[3] for f in filas], color=AQUA)
    a3.axhline(5, color=CRITICO, linewidth=1, linestyle="--")
    a3.set_ylabel("Errores (%)")
    a3.set_xlabel("Segundos desde el inicio (intervalos de 5 s)")
    fig.savefig(SALIDA / f"serie-{carpeta.name}.png")
    plt.close(fig)


def grafica_recuperacion():
    archivo = RESULTADOS / "05-recuperacion" / "vaciado-cola.csv"
    if not archivo.exists():
        return
    with open(archivo, encoding="utf-8-sig") as f:
        filas = list(csv.DictReader(f))
    t = [int(r["segundos"]) for r in filas]
    vis = [int(r["visibles"]) for r in filas]
    proc = [int(r["en_proceso"]) for r in filas]
    fig, ax = plt.subplots(figsize=(8, 4.5))
    ax.plot(t, vis, color=AZUL, label="Mensajes visibles (en espera)")
    ax.plot(t, proc, color=NARANJA, label="Mensajes en proceso")
    etiqueta_final(ax, t[0], vis[0], f"{vis[0]:,} al cortar la carga", AZUL)
    ax.annotate(f"Cola vacia a los {t[-1]} s", (t[-1], 0), xytext=(-10, 14), textcoords="offset points", ha="right",
                color=TEXTO, fontsize=9)
    ax.set_xlabel("Segundos despues de detener la carga")
    ax.set_ylabel("Mensajes en SQS")
    ax.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}"))
    ax.set_title("Actividad 5: vaciado de la cola SQS")
    ax.legend(loc="upper right")
    fig.savefig(SALIDA / "recuperacion-sqs.png")
    plt.close(fig)


def grafica_cloudwatch_recuperacion():
    """SQS visibles y concurrencia de las Lambdas (CloudWatch) durante la Actividad 5."""
    archivo = RESULTADOS / "05-recuperacion" / "cloudwatch.json"
    if not archivo.exists():
        return
    cw = leer(archivo)
    rec = leer(RESULTADOS / "05-recuperacion" / "recuperacion.json")
    corte = datetime.fromisoformat(rec["corte_carga_utc"].replace("Z", "+00:00"))

    def serie(mid):
        pts = cw[mid]["serie"]
        return [(datetime.fromisoformat(p[0].replace("Z", "+00:00")) - corte).total_seconds() / 60 for p in pts], [p[1] for p in pts]

    fig, (a1, a2) = plt.subplots(2, 1, figsize=(9, 6.5), sharex=True)
    x, y = serie("sqs_visible")
    a1.plot(x, y, color=AZUL, marker="o", markersize=5)
    a1.set_ylabel("Mensajes visibles")
    a1.yaxis.set_major_formatter(FuncFormatter(lambda v, _: f"{v:,.0f}"))
    a1.set_title("Actividad 5 (CloudWatch): cola SQS y concurrencia de las Lambdas")
    for mid, etiqueta, color in (("api_concurrency", "Lambda principal", AZUL), ("notif_concurrency", "Notification Lambda", NARANJA)):
        x, y = serie(mid)
        a2.plot(x, y, color=color, label=etiqueta, marker="o", markersize=5)
    a2.set_ylabel("Ejecuciones concurrentes")
    a2.set_xlabel("Minutos respecto al corte de la carga")
    a2.legend(loc="upper right")
    for a in (a1, a2):
        a.axvline(0, color=TEXTO_2, linewidth=1, linestyle="--")
    a1.annotate("Corte de la carga", (0, a1.get_ylim()[1]), xytext=(4, -12), textcoords="offset points", color=TEXTO_2, fontsize=9)
    fig.savefig(SALIDA / "recuperacion-cloudwatch.png")
    plt.close(fig)


def tabla(todos):
    filas = [
        "| Escenario | VUs | Requests | Throughput (req/s) | Exitosas/s | Promedio (ms) | Min (ms) | Max (ms) "
        "| P95 (ms) | P99 (ms) | Errores | Codigos HTTP |",
        "|---|---|---|---|---|---|---|---|---|---|---|---|",
    ]
    for m in todos:
        l = m["latencia_ms"]
        d = desglose(m["escenario"])
        codigos = ", ".join(f"{k}: {v:,}" for k, v in sorted(d["codigos_http"].items())) if d else "-"
        filas.append(
            f"| {m['escenario']} | {m['vus']} | {m['requests']:,} | {m['throughput_rps']:.1f} | "
            f"{m['throughput_rps'] * (1 - m['tasa_errores']):.1f} | {l['promedio']:,.0f} | "
            f"{l['minimo']:,.0f} | {l['maximo']:,.0f} | {l['p95']:,.0f} | {l['p99']:,.0f} | "
            f"{m['tasa_errores'] * 100:.2f} % | {codigos} |"
        )
    (SALIDA / "tabla-resultados.md").write_text("\n".join(filas) + "\n", encoding="utf-8")


def main():
    SALIDA.mkdir(exist_ok=True)
    todos = []
    for prefijo, sufijo, titulo in (("02-", "progresivo", "Actividad 2"), ("04-", "estres", "Actividad 4")):
        datos = escenarios(prefijo)
        todos += datos
        if len(datos) < 2:
            continue
        grafica_latencia(datos, f"{sufijo}-latencia.png", f"{titulo}: latencia por numero de usuarios")
        grafica_throughput(datos, f"{sufijo}-throughput.png", f"{titulo}: throughput por numero de usuarios")
        grafica_barras(datos, lambda m: m["tasa_errores"] * 100, f"{sufijo}-errores.png",
                       f"{titulo}: tasa de errores por numero de usuarios", "Errores (%)", lambda v: f"{v:.1f} %", umbral=5)
    todos = escenarios("01-") + todos + escenarios("05-")
    tabla(todos)
    for carpeta in sorted(RESULTADOS.iterdir()):
        if carpeta.is_dir() and not carpeta.name.startswith("00"):
            grafica_serie(carpeta)
    grafica_recuperacion()
    grafica_cloudwatch_recuperacion()
    print(f"Graficas en {SALIDA}")


if __name__ == "__main__":
    main()
