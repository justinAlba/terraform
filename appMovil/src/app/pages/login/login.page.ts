import { Component } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { LoginViewModel } from './login.viewmodel';

@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
  standalone: false,
  providers: [LoginViewModel],
})
export class LoginPage {
  readonly form = this.fb.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  readonly cargando$ = this.viewModel.cargando$;
  readonly error$ = this.viewModel.error$;

  constructor(private fb: FormBuilder, private viewModel: LoginViewModel) {}

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { email, password } = this.form.getRawValue();
    this.viewModel.login(email!, password!);
  }
}
