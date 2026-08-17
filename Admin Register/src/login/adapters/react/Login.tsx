import { useEffect, useLayoutEffect, useRef, useState } from 'react';
import type { FormEvent } from 'react';
import { AnimatePresence, motion } from 'motion/react';
import type { AuthenticationPort } from '../../domain/login';
import { GraphQLLoginService } from '../../application/graphql-login-service';
import BackgroundScene from './BackgroundScene';
import MorphTiles from './MorphTiles';
import WindowTiles from '../../../ui/adapters/react/WindowTiles';
import styles from './Login.module.css';

const LOGO_SRC = '/cajaIncasurLogo.jpg';
const AUTO_MORPH_MS = 1133;
const MENU_BG = '#f5f7fa';

type Phase = 'logo' | 'morphing' | 'login' | 'exiting';

interface LoginProps {
	port?: AuthenticationPort;
}

export default function Login({ port = new GraphQLLoginService() }: LoginProps) {
	const [phase, setPhase] = useState<Phase>('logo');
	const [slotSize, setSlotSize] = useState(360);
	const slotRef = useRef<HTMLDivElement>(null);

	const [identificationNumber, setIdentificationNumber] = useState('');
	const [password, setPassword] = useState('');
	const [remember, setRemember] = useState(false);
	const [showPassword, setShowPassword] = useState(false);
	const [loading, setLoading] = useState(false);
	const [error, setError] = useState<string | null>(null);

	useEffect(() => {
		const timer = setTimeout(() => setPhase('morphing'), AUTO_MORPH_MS);
		return () => clearTimeout(timer);
	}, []);

	useLayoutEffect(() => {
		if (phase !== 'logo' && slotRef.current) {
			setSlotSize(slotRef.current.clientWidth || 360);
		}
	}, [phase]);

	const grid = Math.max(4, Math.min(12, Math.round(slotSize / 40)));

	const goToMenu = () => {
		window.location.href = '/menu';
	};

	const handleSubmit = async (event: FormEvent<HTMLFormElement>) => {
		event.preventDefault();
		setLoading(true);
		setError(null);

		const result = await port.authenticate({ identificationNumber, password });

		setLoading(false);
		if (result.ok) {
			setPhase('exiting');
		} else {
			setError(result.error);
		}
	};

	return (
		<div className={styles.page}>
			<BackgroundScene />

			<div className={styles.stage}>
				<AnimatePresence>
					{phase === 'logo' && (
						<motion.button
							key="logo"
							type="button"
							className={styles.logoBtn}
							onClick={() => setPhase('morphing')}
							exit={{ opacity: 0, scale: 0.4, transition: { duration: 0.33, ease: 'circIn' } }}
						>
							<span className={styles.glow} />
							<motion.img
								src={LOGO_SRC}
								alt="Incasur"
								className={styles.logo}
								draggable={false}
								animate={{ scale: [1, 1.05, 1], y: [0, -9, 0] }}
								transition={{ duration: 2.67, repeat: Infinity, ease: 'easeInOut' }}
							/>
						</motion.button>
					)}

					{phase !== 'logo' && (
						<div key="card" className={styles.cardSlot} ref={slotRef}>
							<motion.div
								className={styles.card}
								initial={{ opacity: 0, scale: 0.92 }}
								animate={{ opacity: 1, scale: 1 }}
								transition={{ delay: 0.2, duration: 0.33, ease: [0.22, 1, 0.36, 1] }}
							>
								<>
									<div className={styles.brand}>
										<h1>Admin Register</h1>
										<p>Panel de administración</p>
									</div>

									<form className={styles.form} onSubmit={handleSubmit}>
											<label className={styles.field}>
												<span className={styles.label}>Documento de identidad</span>
												<input
													className={styles.input}
													type="text"
													value={identificationNumber}
													onChange={(event) => setIdentificationNumber(event.target.value)}
													placeholder="ej. DNI, RUC"
													inputMode="numeric"
													autoComplete="username"
													required
												/>
											</label>

											<label className={styles.field}>
												<span className={styles.label}>Contraseña</span>
												<div className={styles.password}>
													<input
														className={styles.input}
														type={showPassword ? 'text' : 'password'}
														value={password}
														onChange={(event) => setPassword(event.target.value)}
														placeholder="••••••••"
														autoComplete="current-password"
														required
													/>
													<button
														type="button"
														className={styles.toggle}
														onClick={() => setShowPassword((value) => !value)}
														aria-label={showPassword ? 'Ocultar contraseña' : 'Mostrar contraseña'}
													>
														{showPassword ? 'Ocultar' : 'Mostrar'}
													</button>
												</div>
											</label>

											<div className={styles.options}>
												<label className={styles.remember}>
													<input
														type="checkbox"
														checked={remember}
														onChange={(event) => setRemember(event.target.checked)}
													/>
													<span>Recordarme</span>
												</label>
												<a className={styles.link} href="#">
													¿Olvidaste tu contraseña?
												</a>
											</div>

											{error && (
												<p className={styles.error} role="alert">
													{error}
												</p>
											)}

											<button type="submit" className={styles.submit} disabled={loading}>
												{loading ? 'Verificando…' : 'Iniciar sesión'}
											</button>
										</form>

									<p className={styles.footer}>© {new Date().getFullYear()} Incasur S.A.C.</p>
								</>
							</motion.div>

							<AnimatePresence>
								{phase === 'morphing' && (
									<MorphTiles
										key="tiles"
										src={LOGO_SRC}
										cols={grid}
										rows={grid}
										width={slotSize}
										height={slotSize}
										onComplete={() => setPhase('login')}
									/>
								)}
							</AnimatePresence>
						</div>
					)}
				</AnimatePresence>
			</div>

			{phase === 'exiting' && (
				<WindowTiles color={MENU_BG} mode="cover" onComplete={goToMenu} />
			)}
		</div>
	);
}
