import type { AuthenticationPort, LoginCredentials, LoginResult } from '../domain/login';

/**
 * Use case — implementa el port con reglas mock.
 * Reemplazado por graphql-login-service.ts (API real).
 * Se conserva por si se necesita un modo de desarrollo sin backend.
 */
export class LoginService implements AuthenticationPort {
	async authenticate(credentials: LoginCredentials): Promise<LoginResult> {
		await new Promise((resolve) => setTimeout(resolve, 400));

		const valid =
			credentials.identificationNumber.trim().length > 0 &&
			credentials.password.trim().length >= 4;

		if (!valid) {
			return { ok: false, error: 'Documento o contraseña inválidos.' };
		}

		return {
			ok: true,
			user: { identificationNumber: credentials.identificationNumber.trim(), role: 'admin' },
		};
	}
}
