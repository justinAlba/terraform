import { Component, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { SettingsViewModel } from './settings.viewmodel';

@Component({
  selector: 'app-settings',
  templateUrl: './settings.page.html',
  styleUrls: ['./settings.page.scss'],
  standalone: false,
  providers: [SettingsViewModel],
})
export class SettingsPage implements OnInit {
  readonly form = this.fb.group({
    host: ['', [Validators.required, Validators.pattern(/^https?:\/\/.+/)]],
  });

  readonly estadoPrueba$ = this.viewModel.estadoPrueba$;
  readonly guardado$ = this.viewModel.guardado$;

  constructor(private fb: FormBuilder, private viewModel: SettingsViewModel) {}

  ngOnInit(): void {
    this.form.patchValue({ host: this.viewModel.hostActual() });
  }

  probar(): void {
    const host = this.form.getRawValue().host;
    if (host) {
      this.viewModel.probarConexion(host);
    }
  }

  guardar(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.viewModel.guardar(this.form.getRawValue().host!);
  }

  async restablecer(): Promise<void> {
    const host = await this.viewModel.restablecer();
    this.form.patchValue({ host });
  }
}
