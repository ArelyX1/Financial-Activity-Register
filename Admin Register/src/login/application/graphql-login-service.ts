import type { AuthenticationPort, LoginCredentials, LoginResult } from '../domain/login';
import { graphql, canAccessAdmin } from '../../auth/api';
import { saveSession } from '../../auth/session';

interface LoginPayload {
	success: boolean;
	access_token?: string | null;
	refresh_token?: string | null;
	roles?: string[];
}

/**
 * Use case — implementa el port con la API real del backend.
 */
export class GraphQLLoginService implements AuthenticationPort {
	async authenticate(credentials: LoginCredentials): Promise<LoginResult> {
		try {
			const login = await graphql<{ login: LoginPayload }>(
				`mutation Login($identificationNumber: String!, $password: String!) {
					login(identification_number: $identificationNumber, password: $password) {
						success
						access_token
						refresh_token
						roles
					}
				}`,
				{
					identificationNumber: credentials.identificationNumber,
					password: credentials.password,
				}
			);

			if (!login.login.success || !login.login.access_token) {
				return { ok: false, error: 'Documento o contraseña inválidos.' };
			}

			const hasAccess = await canAccessAdmin(login.login.access_token);

			if (!hasAccess) {
				return { ok: false, error: 'No tiene acceso al panel de administración.' };
			}

			saveSession(login.login.access_token, login.login.refresh_token ?? undefined);

			return {
				ok: true,
				user: {
					identificationNumber: credentials.identificationNumber,
					role: login.login.roles?.[0] ?? 'admin',
				},
			};
		} catch (error) {
			return {
				ok: false,
				error: error instanceof Error ? error.message : 'Error de conexión con la API',
			};
		}
	}
}
