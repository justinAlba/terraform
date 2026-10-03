import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';
import { delay } from 'rxjs/operators';
import { Configuracion } from '../models/dashboard.model';

@Injectable({ providedIn: 'root' })
export class DashboardService {
  obtenerConfiguracion(): Observable<Configuracion> {
    const configuracion: Configuracion = {
      tema: 'claro',
      idioma: 'es',
      notificacionesActivas: true,
    };
    return of(configuracion).pipe(delay(600));
  }
}
