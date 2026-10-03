import { HttpEvent, HttpHandler, HttpInterceptor, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { ApiConfigService } from '../services/api-config.service';

@Injectable()
export class BaseUrlInterceptor implements HttpInterceptor {
  constructor(private apiConfig: ApiConfigService) {}

  intercept(req: HttpRequest<unknown>, next: HttpHandler): Observable<HttpEvent<unknown>> {
    if (!req.url.startsWith('/')) {
      return next.handle(req);
    }

    const cloned = req.clone({ url: `${this.apiConfig.getHost()}${req.url}` });
    return next.handle(cloned);
  }
}
