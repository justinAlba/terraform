import { Injectable } from '@angular/core';
import { CanActivate, Router, UrlTree } from '@angular/router';
import { Observable, from, map } from 'rxjs';
import { TokenStorageService } from '../services/token-storage.service';

@Injectable({ providedIn: 'root' })
export class AuthGuard implements CanActivate {
  constructor(private tokenStorage: TokenStorageService, private router: Router) {}

  canActivate(): Observable<boolean | UrlTree> {
    return from(this.tokenStorage.getToken()).pipe(
      map((token) => (token ? true : this.router.createUrlTree(['/login'])))
    );
  }
}
