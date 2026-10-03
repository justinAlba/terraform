import { Injectable } from '@angular/core';
import { Storage } from '@ionic/storage-angular';

const TOKEN_KEY = 'auth_token';

@Injectable({ providedIn: 'root' })
export class TokenStorageService {
  private storage: Storage | null = null;
  private ready: Promise<Storage>;

  constructor(private ionicStorage: Storage) {
    this.ready = this.ionicStorage.create();
  }

  async setToken(token: string): Promise<void> {
    this.storage = await this.ready;
    await this.storage.set(TOKEN_KEY, token);
  }

  async getToken(): Promise<string | null> {
    this.storage = await this.ready;
    return this.storage.get(TOKEN_KEY);
  }

  async clearToken(): Promise<void> {
    this.storage = await this.ready;
    await this.storage.remove(TOKEN_KEY);
  }
}
