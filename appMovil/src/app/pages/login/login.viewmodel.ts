import { Injectable } from '@angular/core';
import { HttpErrorResponse } from '@angular/common/http';
import { Router } from '@angular/router';
import { BehaviorSubject } from 'rxjs';
import { AuthRepository } from '../../repositories/auth.repository';

@Injectable()
export class LoginViewModel {
  readonly cargando$ = new BehaviorSubject<boolean>(false);
  readonly error$ = new BehaviorSubject<string | null>(null);

  constructor(private authRepository: AuthRepository, private router: Router) {}

  login(email: string, password: string): void {
    this.cargando$.next(true);
    this.error$.next(null);

    this.authRepository.login({ email, password }).subscribe({
      next: () => {
        this.cargando$.next(false);
        this.router.navigateByUrl('/dashboard');
      },
      error: (error: HttpErrorResponse) => {
        this.cargando$.next(false);
        this.error$.next(this.mapearError(error));
      },
    });
  }

  private mapearError(error: HttpErrorResponse): string {
    if (error.status === 401) {
      return 'Correo o contrasena incorrectos.';
    }
    return 'No se pudo iniciar sesion. Intenta de nuevo.';
  }
}
