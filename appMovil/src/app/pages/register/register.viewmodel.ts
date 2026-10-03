import { HttpErrorResponse } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { AuthRepository } from '../../repositories/auth.repository';

@Injectable()
export class RegisterViewModel {
  readonly cargando$ = new BehaviorSubject<boolean>(false);
  readonly error$ = new BehaviorSubject<string | null>(null);

  constructor(private authRepository: AuthRepository, private router: Router) {}

  registrar(nombre: string, email: string, password: string): void {
    this.cargando$.next(true);
    this.error$.next(null);

    this.authRepository.registrar({ nombre, email, password }).subscribe({
      next: () => {
        this.cargando$.next(false);
        this.router.navigateByUrl('/login');
      },
      error: (error: HttpErrorResponse) => {
        this.cargando$.next(false);
        this.error$.next(this.mapearError(error));
      },
    });
  }

  private mapearError(error: HttpErrorResponse): string {
    if (error.status === 409) {
      return 'Ya existe un usuario con ese correo.';
    }
    if (error.status === 400) {
      return 'Revisa los datos ingresados.';
    }
    return 'No se pudo completar el registro. Intenta de nuevo.';
  }
}
