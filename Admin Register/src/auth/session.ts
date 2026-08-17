/**
 * Session — persistencia del token de acceso.
 * Guarda el token en localStorage para que las rutas protegidas
 * puedan verificar que el usuario sigue autenticado.
 */

const ACCESS_TOKEN_KEY = 'admin_register_access_token';
const REFRESH_TOKEN_KEY = 'admin_register_refresh_token';

export function saveSession(accessToken: string, refreshToken?: string): void {
	localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
	if (refreshToken) {
		localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
	}
}

export function getAccessToken(): string | null {
	return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function clearSession(): void {
	localStorage.removeItem(ACCESS_TOKEN_KEY);
	localStorage.removeItem(REFRESH_TOKEN_KEY);
}
