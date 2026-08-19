/**
 * API — cliente GraphQL compartido.
 * La URL se lee del .env (PUBLIC_API_URL) en build time.
 */

import { getRefreshToken, saveSession, clearSession } from './session';

const API_URL: string | undefined = import.meta.env.PUBLIC_API_URL;

interface GraphQLError {
	message?: string;
}

export async function graphql<T>(
	query: string,
	variables: Record<string, unknown>
): Promise<T> {
	if (!API_URL) {
		throw new Error('PUBLIC_API_URL no está configurado en el .env');
	}

	const response = await fetch(API_URL, {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ query, variables }),
	});

	const body = (await response.json()) as { data?: T; errors?: GraphQLError[] };

	if (response.status !== 200 || body.errors?.length) {
		throw new Error(body.errors?.[0]?.message ?? 'Error de conexión con la API');
	}

	return body.data as T;
}

/** Verifica contra el backend si el token tiene acceso al panel admin (permiso ACC-A). */
export async function canAccessAdmin(token: string): Promise<boolean> {
	const data = await graphql<{ go_admin_page: boolean }>(
		`query CanAccessAdmin($token: String!) {
			go_admin_page(token: $token)
		}`,
		{ token }
	);
	return data.go_admin_page;
}

/** Refresca el par de tokens usando el refresh_token. */
export async function refreshAccessToken(): Promise<boolean> {
	const refreshToken = getRefreshToken();
	if (!refreshToken) return false;

	try {
		const data = await graphql<{
			refresh_token: {
				success: boolean;
				access_token: string | null;
				refresh_token: string | null;
				access_token_expires_at: string | null;
			};
		}>(
			`mutation RefreshToken($refreshToken: String!) {
				refresh_token(refresh_token: $refreshToken) {
					success
					access_token
					refresh_token
					access_token_expires_at
				}
			}`,
			{ refreshToken }
		);

		const payload = data.refresh_token;
		if (!payload.success || !payload.access_token) {
			clearSession();
			return false;
		}

		saveSession(
			payload.access_token,
			payload.refresh_token ?? undefined,
			payload.access_token_expires_at ?? undefined,
		);
		return true;
	} catch {
		clearSession();
		return false;
	}
}

/** Obtiene los datos del usuario autenticado (nombre, foto). */
export async function fetchCurrentUser(
	identificationNumber: string,
): Promise<{ name: string; photoUrl: string } | null> {
	try {
		const data = await graphql<{
			person: {
				name: string | null;
				photo_url: string | null;
			} | null;
		}>(
			`query GetPerson($id: String!) {
				person(identification_number: $id) {
					name
					photo_url
				}
			}`,
			{ id: identificationNumber }
		);

		if (!data.person) return null;
		return {
			name: data.person.name ?? '',
			photoUrl: data.person.photo_url ?? '',
		};
	} catch {
		return null;
	}
}
