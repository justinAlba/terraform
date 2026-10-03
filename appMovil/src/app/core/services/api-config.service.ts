import { Injectable } from '@angular/core';
import { Storage } from '@ionic/storage-angular';
import { BehaviorSubject } from 'rxjs';
import { environment } from '../../../environments/environment';

const HOST_KEY = 'api_host';

@Injectable({ providedIn: 'root' })
export class ApiConfigService {
  private readonly host$$ = new BehaviorSubject<string>(environment.baseUrl);
  readonly host$ = this.host$$.asObservable();

  private storage: Storage | null = null;
  private ready: Promise<Storage>;

  constructor(private ionicStorage: Storage) {
    this.ready = this.ionicStorage.create();
    this.ready.then(async (storage) => {
      this.storage = storage;
      const host = await storage.get(HOST_KEY);
      if (host) {
        this.host$$.next(host);
      }
    });
  }

  getHost(): string {
    return this.host$$.getValue();
  }

  async setHost(host: string): Promise<void> {
    const limpio = this.normalizar(host);
    this.storage = await this.ready;
    await this.storage.set(HOST_KEY, limpio);
    this.host$$.next(limpio);
  }

  async restablecerPorDefecto(): Promise<void> {
    this.storage = await this.ready;
    await this.storage.remove(HOST_KEY);
    this.host$$.next(environment.baseUrl);
  }

  private normalizar(host: string): string {
    return host.trim().replace(/\/+$/, '');
  }
}
