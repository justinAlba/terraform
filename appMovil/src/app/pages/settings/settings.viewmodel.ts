import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { BehaviorSubject, firstValueFrom } from 'rxjs';
import { ApiConfigService } from '../../core/services/api-config.service';

export type EstadoPrueba = 'inactivo' | 'probando' | 'ok' | 'error';

@Injectable()
export class SettingsViewModel {
  readonly host$ = this.apiConfig.host$;
  readonly estadoPrueba$ = new BehaviorSubject<EstadoPrueba>('inactivo');
  readonly guardado$ = new BehaviorSubject<boolean>(false);

  constructor(private apiConfig: ApiConfigService, private http: HttpClient) {}

  hostActual(): string {
    return this.apiConfig.getHost();
  }

  async guardar(host: string): Promise<void> {
    await this.apiConfig.setHost(host);
    this.guardado$.next(true);
    setTimeout(() => this.guardado$.next(false), 2000);
  }

  async restablecer(): Promise<string> {
    await this.apiConfig.restablecerPorDefecto();
    return this.apiConfig.getHost();
  }

  async probarConexion(host: string): Promise<void> {
    this.estadoPrueba$.next('probando');
    const limpio = host.trim().replace(/\/+$/, '');
    try {
      await firstValueFrom(this.http.get(`${limpio}/api/usuarios`, { observe: 'response', responseType: 'text' }));
      this.estadoPrueba$.next('ok');
    } catch (error: any) {
      this.estadoPrueba$.next(error?.status > 0 ? 'ok' : 'error');
    }
  }
}
