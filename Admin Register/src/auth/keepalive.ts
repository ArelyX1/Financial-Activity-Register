/**
 * Keepalive — mantiene el access token vigente mientras el usuario
 * está activo. Si detecta inactividad, no refresca: al expirar,
 * la siguiente petición manda al login.
 */

import { getAccessToken, isTokenExpiringSoon, wasActiveRecently, startActivityTracking } from './session';
import { refreshOnce } from './api';

const CHECK_INTERVAL = 30_000;
const REFRESH_AHEAD = 90_000;
const ACTIVITY_WINDOW = 120_000;

export function startSessionKeepAlive(): () => void {
	const stopActivity = startActivityTracking();

	const tryRefresh = () => {
		if (!wasActiveRecently(ACTIVITY_WINDOW)) return;
		if (!getAccessToken()) return;
		if (isTokenExpiringSoon(REFRESH_AHEAD)) void refreshOnce();
	};

	const timer = setInterval(tryRefresh, CHECK_INTERVAL);
	const onVisible = () => {
		if (document.visibilityState === 'visible') tryRefresh();
	};
	document.addEventListener('visibilitychange', onVisible);

	return () => {
		clearInterval(timer);
		document.removeEventListener('visibilitychange', onVisible);
		stopActivity();
	};
}
