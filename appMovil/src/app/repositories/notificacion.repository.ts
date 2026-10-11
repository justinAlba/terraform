import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { NotificacionRequest, NotificacionResponse } from '../core/models/notificacion.model';
import { NotificacionService } from '../core/services/notificacion.service';

@Injectable({ providedIn: 'root' })
export class NotificacionRepository {
  constructor(private notificacionService: NotificacionService) {}

  enviar(request: NotificacionRequest): Observable<NotificacionResponse> {
    return this.notificacionService.enviar(request);
  }
}
