import { HttpEvent, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { TokenStorageService } from '../services/token-storage.service';

@Injectable()
export class JwtInterceptor implements HttpInterceptor {
  constructor(private tokenStorage: TokenStorageService) {}

  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    if (req.url.includes('/auth/')) {
      return next.handle(req);
    }

    return from(this.tokenStorage.getToken()).pipe(
      switchMap((token) => {
        if (!token) {
          return next.handle(req);
        }
        const cloned = req.clone({
          setHeaders: { Authorization: `Bearer ${token}` },
        });
        return next.handle(cloned);
      })
    );
  }
}
