import { HttpEventType } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { UploadResponse } from '../core/models/upload.model';
import { UploadService } from '../core/services/upload.service';

export interface EstadoSubida {
  progreso: number;
  completado: boolean;
  resultado?: UploadResponse;
}

@Injectable({ providedIn: 'root' })
export class UploadRepository {
  constructor(private uploadService: UploadService) {}

  subir(file: File | Blob, filename?: string): Observable<EstadoSubida> {
    return this.uploadService.subir(file, filename).pipe(
      map((evento) => {
        if (evento.type === HttpEventType.UploadProgress && evento.total) {
          return { progreso: Math.round((100 * evento.loaded) / evento.total), completado: false };
        }
        if (evento.type === HttpEventType.Response) {
          return { progreso: 100, completado: true, resultado: evento.body ?? undefined };
        }
        return { progreso: 0, completado: false };
      })
    );
  }
}
