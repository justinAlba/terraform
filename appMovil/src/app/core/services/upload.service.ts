import { HttpClient, HttpEvent, HttpRequest } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { UploadResponse } from '../models/upload.model';

@Injectable({ providedIn: 'root' })
export class UploadService {
  private readonly baseUrl = '/api/upload';

  constructor(private http: HttpClient) {}

  subir(file: File | Blob, filename?: string): Observable<HttpEvent<UploadResponse>> {
    const formData = new FormData();
    formData.append('file', file, filename);

    const request = new HttpRequest('POST', this.baseUrl, formData, {
      reportProgress: true,
    });

    return this.http.request<UploadResponse>(request);
  }
}
