import { useEffect, useState, type ReactNode } from 'react';
import { getAccessToken, isTokenExpiringSoon, clearSession } from '../../session';
import { canAccessAdmin, refreshAccessToken } from '../../api';

/**
 * Guard — protege una ruta verificando el token contra el backend.
 * Si el token está por expirar, lo refresca automáticamente.
 * Si el usuario no está autenticado o no tiene permiso de admin (ACC-A),
 * redirige a / y limpia la sesión.
 */

type AuthState = 'checking' | 'allowed' | 'denied';

export default function RequireAuth({ children }: { children: ReactNode }) {
	const [state, setState] = useState<AuthState>('checking');

	useEffect(() => {
		let cancelled = false;

		async function verify() {
			let token = getAccessToken();
			if (!token) {
				if (!cancelled) setState('denied');
				return;
			}

			// Auto-refresh if token is about to expire (within 60s)
			if (isTokenExpiringSoon(60_000)) {
				const refreshed = await refreshAccessToken();
				if (cancelled) return;
				if (!refreshed) {
					setState('denied');
					return;
				}
				token = getAccessToken();
				if (!token) {
					setState('denied');
					return;
				}
			}

			try {
				const ok = await canAccessAdmin(token);
				if (cancelled) return;
				if (ok) {
					setState('allowed');
				} else {
					clearSession();
					setState('denied');
				}
			} catch {
				if (!cancelled) setState('denied');
			}
		}

		verify();

		return () => {
			cancelled = true;
		};
	}, []);

	useEffect(() => {
		if (state === 'denied') {
			window.location.href = '/';
		}
	}, [state]);

	if (state !== 'allowed') {
		return (
			<div
				style={{
					minHeight: '100vh',
					display: 'flex',
					alignItems: 'center',
					justifyContent: 'center',
					background: '#f5f7fa',
					color: '#12667f',
					fontFamily: 'Inter, sans-serif',
					fontSize: 16,
				}}
			>
				Verificando acceso…
			</div>
		);
	}

	return <>{children}</>;
}
