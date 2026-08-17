/**
 * API — cliente GraphQL compartido.
 * La URL se lee del .env (PUBLIC_API_URL) en build time.
 */

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
