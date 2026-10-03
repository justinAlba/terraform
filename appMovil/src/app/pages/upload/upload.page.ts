import { Component } from '@angular/core';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { ApiConfigService } from '../../core/services/api-config.service';
import { UploadViewModel } from './upload.viewmodel';

@Component({
  selector: 'app-upload',
  templateUrl: './upload.page.html',
  styleUrls: ['./upload.page.scss'],
  standalone: false,
  providers: [UploadViewModel],
})
export class UploadPage {
  readonly progreso$ = this.viewModel.progreso$;
  readonly subiendo$ = this.viewModel.subiendo$;
  readonly resultado$ = this.viewModel.resultado$;
  readonly error$ = this.viewModel.error$;

  previewUrl: string | null = null;
  esImagen = false;
  nombreArchivo: string | null = null;

  private archivoSeleccionado: File | Blob | null = null;

  constructor(private viewModel: UploadViewModel, private apiConfig: ApiConfigService) {}

  urlCompleta(url: string): string {
    return url.startsWith('http') ? url : `${this.apiConfig.getHost()}${url}`;
  }

  async tomarOSeleccionarFoto(): Promise<void> {
    const foto = await Camera.getPhoto({
      resultType: CameraResultType.Uri,
      source: CameraSource.Prompt,
      quality: 80,
    });

    if (!foto.webPath) {
      return;
    }

    const respuesta = await fetch(foto.webPath);
    const blob = await respuesta.blob();

    this.archivoSeleccionado = blob;
    this.previewUrl = foto.webPath;
    this.esImagen = true;
    this.nombreArchivo = `foto-${Date.now()}.${foto.format ?? 'jpeg'}`;
  }

  onDocumentoSeleccionado(evento: Event): void {
    const input = evento.target as HTMLInputElement;
    const archivo = input.files?.[0];
    if (!archivo) {
      return;
    }

    this.archivoSeleccionado = archivo;
    this.nombreArchivo = archivo.name;
    this.esImagen = archivo.type.startsWith('image/');
    this.previewUrl = this.esImagen ? URL.createObjectURL(archivo) : null;
  }

  subir(): void {
    if (!this.archivoSeleccionado) {
      return;
    }
    this.viewModel.subir(this.archivoSeleccionado, this.nombreArchivo ?? undefined);
  }
}
