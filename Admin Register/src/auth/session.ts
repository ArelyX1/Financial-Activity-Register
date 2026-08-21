/**
 * Session — persistencia del token de acceso y datos del usuario.
 * Guarda el token en localStorage para que las rutas protegidas
 * puedan verificar que el usuario sigue autenticado.
 */

const ACCESS_TOKEN_KEY = 'admin_register_access_token';
const REFRESH_TOKEN_KEY = 'admin_register_refresh_token';
const TOKEN_EXPIRES_KEY = 'admin_register_token_expires';
const USER_KEY = 'admin_register_user';

export interface SessionUser {
	identificationNumber: string;
	name: string;
	photoUrl: string;
}

export function saveSession(
	accessToken: string,
	refreshToken?: string,
	expiresAtIso?: string | number | null,
): void {
	localStorage.setItem(ACCESS_TOKEN_KEY, accessToken);
	if (refreshToken) {
		localStorage.setItem(REFRESH_TOKEN_KEY, refreshToken);
	}
	if (expiresAtIso) {
		const ts = typeof expiresAtIso === 'string'
			? new Date(expiresAtIso).getTime()
			: expiresAtIso;
		localStorage.setItem(TOKEN_EXPIRES_KEY, String(ts));
	}
}

export function getAccessToken(): string | null {
	return localStorage.getItem(ACCESS_TOKEN_KEY);
}

export function getRefreshToken(): string | null {
	return localStorage.getItem(REFRESH_TOKEN_KEY);
}

export function getTokenExpiresAt(): number | null {
	const raw = localStorage.getItem(TOKEN_EXPIRES_KEY);
	return raw ? Number(raw) : null;
}

export function isTokenExpiringSoon(withinMs = 60_000): boolean {
	const expires = getTokenExpiresAt();
	if (!expires) return false;
	return Date.now() >= expires - withinMs;
}

const EXPIRY_GRACE_MS = 5_000;

export function sessionExpiredByInactivity(): boolean {
	const expires = getTokenExpiresAt();
	return expires !== null && Date.now() > expires + EXPIRY_GRACE_MS;
}

export function saveUser(user: SessionUser): void {
	localStorage.setItem(USER_KEY, JSON.stringify(user));
}

export function getUser(): SessionUser | null {
	const raw = localStorage.getItem(USER_KEY);
	if (!raw) return null;
	try {
		return JSON.parse(raw) as SessionUser;
	} catch {
		return null;
	}
}

export function clearSession(): void {
	localStorage.removeItem(ACCESS_TOKEN_KEY);
	localStorage.removeItem(REFRESH_TOKEN_KEY);
	localStorage.removeItem(TOKEN_EXPIRES_KEY);
	localStorage.removeItem(USER_KEY);
}

const ACTIVITY_EVENTS = ['pointerdown', 'keydown', 'wheel', 'touchstart'] as const;

let lastActivity = Date.now();

export function touchActivity(): void {
	lastActivity = Date.now();
}

export function wasActiveRecently(withinMs = 120_000): boolean {
	return Date.now() - lastActivity < withinMs;
}

export function startActivityTracking(): () => void {
	const onTouch = () => touchActivity();
	ACTIVITY_EVENTS.forEach(e => window.addEventListener(e, onTouch, { passive: true }));
	return () => {
		ACTIVITY_EVENTS.forEach(e => window.removeEventListener(e, onTouch));
	};
}
