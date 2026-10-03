import { Injectable } from '@angular/core';
import { Observable, forkJoin } from 'rxjs';
import { Configuracion } from '../core/models/dashboard.model';
import { Usuario } from '../core/models/usuario.model';
import { DashboardService } from '../core/services/dashboard.service';
import { UsuarioService } from '../core/services/usuario.service';

export interface DashboardData {
  usuarios: Usuario[];
  perfil: Usuario;
  configuracion: Configuracion;
}

@Injectable({ providedIn: 'root' })
export class DashboardRepository {
  constructor(private usuarioService: UsuarioService, private dashboardService: DashboardService) {}

  cargar(idUsuarioActual: number): Observable<DashboardData> {
    return forkJoin({
      usuarios: this.usuarioService.listar(),
      perfil: this.usuarioService.obtenerPorId(idUsuarioActual),
      configuracion: this.dashboardService.obtenerConfiguracion(),
    });
  }
}
