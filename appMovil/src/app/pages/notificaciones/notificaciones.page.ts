import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { NotificacionesViewModel } from './notificaciones.viewmodel';

@Component({
  selector: 'app-notificaciones',
  templateUrl: './notificaciones.page.html',
  styleUrls: ['./notificaciones.page.scss'],
  standalone: false,
  providers: [NotificacionesViewModel],
})
export class NotificacionesPage {
  readonly form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    subject: ['', [Validators.required, Validators.maxLength(150)]],
    message: ['', [Validators.required, Validators.maxLength(5000)]],
  });

  readonly enviando$ = this.viewModel.enviando$;
  readonly exito$ = this.viewModel.exito$;
  readonly error$ = this.viewModel.error$;

  constructor(private fb: FormBuilder, private viewModel: NotificacionesViewModel) {}

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { email, subject, message } = this.form.getRawValue();
    this.viewModel.enviar(
      { email: email!.trim(), subject: subject!.trim(), message: message! },
      () => this.form.reset()
    );
  }
}
