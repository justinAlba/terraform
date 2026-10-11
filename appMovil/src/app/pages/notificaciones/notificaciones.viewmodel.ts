import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { NotificacionRequest } from '../../core/models/notificacion.model';
import { NotificacionRepository } from '../../repositories/notificacion.repository';

@Injectable()
export class NotificacionesViewModel {
  readonly enviando$ = new BehaviorSubject<boolean>(false);
  readonly exito$ = new BehaviorSubject<string | null>(null);
  readonly error$ = new BehaviorSubject<string | null>(null);

  constructor(private notificacionRepository: NotificacionRepository) {}

  enviar(request: NotificacionRequest, alTerminar: () => void): void {
    this.enviando$.next(true);
    this.exito$.next(null);
    this.error$.next(null);

    this.notificacionRepository.enviar(request).subscribe({
      next: () => {
        this.enviando$.next(false);
        this.exito$.next('Mensaje enviado correctamente.');
        alTerminar();
      },
      error: () => {
        this.enviando$.next(false);
        this.error$.next('Error al enviar mensaje.');
      },
    });
  }
}
