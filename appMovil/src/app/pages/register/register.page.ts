import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { RegisterViewModel } from './register.viewmodel';

@Component({
  selector: 'app-register',
  templateUrl: './register.page.html',
  styleUrls: ['./register.page.scss'],
  standalone: false,
  providers: [RegisterViewModel],
})
export class RegisterPage {
  readonly form = this.fb.group({
    nombre: ['', [Validators.required]],
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  readonly cargando$ = this.viewModel.cargando$;
  readonly error$ = this.viewModel.error$;

  constructor(private fb: FormBuilder, private viewModel: RegisterViewModel) {}

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { nombre, email, password } = this.form.getRawValue();
    this.viewModel.registrar(nombre!, email!, password!);
  }
}
