import { HttpErrorResponse, HttpEvent, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Router } from '@angular/router';
import { Observable, from, throwError } from 'rxjs';
import { catchError, switchMap } from 'rxjs/operators';
import { TokenStorageService } from '../services/token-storage.service';

@Injectable()
export class ErrorInterceptor implements HttpInterceptor {
  constructor(private tokenStorage: TokenStorageService, private router: Router) {}

  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    return next.handle(req).pipe(
      catchError((error: HttpErrorResponse) => {
        const esRutaProtegida = !req.url.includes('/auth/');
        if ((error.status === 401 || error.status === 403) && esRutaProtegida) {
          return from(this.tokenStorage.clearToken()).pipe(
            switchMap(() => {
              this.router.navigateByUrl('/login');
              return throwError(() => error);
            })
          );
        }
        return throwError(() => error);
      })
    );
  }
}
