import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { NotificacionRequest, NotificacionResponse } from '../models/notificacion.model';

@Injectable({ providedIn: 'root' })
export class NotificacionService {
  private readonly baseUrl = '/api/notifications';

  constructor(private http: HttpClient) {}

  enviar(request: NotificacionRequest): Observable<NotificacionResponse> {
    return this.http.post<NotificacionResponse>(`${this.baseUrl}/send`, request);
  }
}
