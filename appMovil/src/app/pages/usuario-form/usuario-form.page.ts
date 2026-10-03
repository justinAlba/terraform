import { Component, OnInit } from '@angular/core';
import { FormBuilder, Validators } from '@angular/forms';
import { ActivatedRoute, Router } from '@angular/router';
import { Rol } from '../../core/models/usuario.model';
import { UsuarioFormViewModel } from './usuario-form.viewmodel';

@Component({
  selector: 'app-usuario-form',
  templateUrl: './usuario-form.page.html',
  styleUrls: ['./usuario-form.page.scss'],
  standalone: false,
  providers: [UsuarioFormViewModel],
})
export class UsuarioFormPage implements OnInit {
  readonly form = this.fb.group({
    nombre: ['', [Validators.required]],
    email: ['', [Validators.required, Validators.email]],
    password: [''],
    rol: ['USUARIO' as Rol, [Validators.required]],
  });

  readonly cargando$ = this.viewModel.cargando$;
  readonly error$ = this.viewModel.error$;

  usuarioId: number | null = null;

  constructor(
    private fb: FormBuilder,
    private viewModel: UsuarioFormViewModel,
    private route: ActivatedRoute,
    private router: Router
  ) {}

  get esEdicion(): boolean {
    return this.usuarioId !== null;
  }

  ngOnInit(): void {
    const idParam = this.route.snapshot.paramMap.get('id');
    if (idParam) {
      this.usuarioId = Number(idParam);
      this.form.get('password')?.clearValidators();
      this.viewModel.cargarUsuario(this.usuarioId, (datos) => {
        this.form.patchValue(datos);
      });
    } else {
      this.form.get('password')?.setValidators([Validators.required, Validators.minLength(6)]);
    }

    this.viewModel.guardado$.subscribe((guardado) => {
      if (guardado) {
        this.router.navigateByUrl('/usuarios-list');
      }
    });
  }

  onSubmit(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    const { nombre, email, password, rol } = this.form.getRawValue();
    if (this.usuarioId !== null) {
      this.viewModel.actualizar(this.usuarioId, nombre!, email!, password || null, rol!);
    } else {
      this.viewModel.crear(nombre!, email!, password!, rol!);
    }
  }
}
