import { Injectable } from '@angular/core';
import { BehaviorSubject } from 'rxjs';
import { UploadResponse } from '../../core/models/upload.model';
import { UploadRepository } from '../../repositories/upload.repository';

@Injectable()
export class UploadViewModel {
  readonly progreso$ = new BehaviorSubject<number>(0);
  readonly subiendo$ = new BehaviorSubject<boolean>(false);
  readonly resultado$ = new BehaviorSubject<UploadResponse | null>(null);
  readonly error$ = new BehaviorSubject<string | null>(null);

  constructor(private uploadRepository: UploadRepository) {}

  subir(file: File | Blob, filename?: string): void {
    this.subiendo$.next(true);
    this.error$.next(null);
    this.resultado$.next(null);
    this.progreso$.next(0);

    this.uploadRepository.subir(file, filename).subscribe({
      next: (estado) => {
        this.progreso$.next(estado.progreso);
        if (estado.completado) {
          this.subiendo$.next(false);
          this.resultado$.next(estado.resultado ?? null);
        }
      },
      error: () => {
        this.subiendo$.next(false);
        this.error$.next('No se pudo subir el archivo.');
      },
    });
  }
}
