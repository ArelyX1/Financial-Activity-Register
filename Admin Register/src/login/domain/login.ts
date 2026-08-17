/**
 * Domain — login feature.
 *
 * Entities and the port (outgoing contract) that the rest of the
 * application depends on. No framework or UI code lives here.
 */

export interface LoginCredentials {
	identificationNumber: string;
	password: string;
}

export interface LoginUser {
	identificationNumber: string;
	role: string;
}

export type LoginResult = { ok: true; user: LoginUser } | { ok: false; error: string };

/**
 * Port that the UI adapter consumes. The concrete implementation is
 * provided by the application layer (dependency inversion).
 */
export interface AuthenticationPort {
	authenticate(credentials: LoginCredentials): Promise<LoginResult>;
}
