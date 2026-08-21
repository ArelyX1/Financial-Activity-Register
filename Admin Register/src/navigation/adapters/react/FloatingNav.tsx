import { useState, useEffect, useRef, useCallback, useMemo } from 'react';
import { motion, AnimatePresence, useDragControls } from 'motion/react';
import { clearSession, getUser, saveUser, getAccessToken, getRefreshToken, type SessionUser } from '../../../auth/session';
import { fetchCurrentUser, graphql } from '../../../auth/api';
import { AssignPermissionsProvider, PermissionsPanel, RolesPanel, AssignmentPanel } from '../../../sistema/adapters/react/AssignPermissions';
import { AddRolePanel } from '../../../sistema/adapters/react/AddRole';
import { EditRolePanel } from '../../../sistema/adapters/react/EditRole';
import styles from './FloatingNav.module.css';

const FOLDERS = [
	{ title: 'Menu', color: '#12667f', path: '/menu' },
	{ title: 'Personal', color: '#c65b5b', path: '/personal' },
	{ title: 'Sistema', color: '#1a7a5c', path: '' },
];

const SISTEMA_SUBOPTIONS = [
	{ label: 'Roles y Permisos' },
	{ label: 'Identificacion' },
	{ label: 'Otros' },
];

const DEFAULT_AVATAR = '/cajaIncasurLogo.jpg';

export default function FloatingNav() {
	const [navOpen, setNavOpen] = useState(false);
	const [hoveredFolder, setHoveredFolder] = useState<number | null>(null);
	const [expandedPersonal, setExpandedPersonal] = useState(false);
	const [personalRotated, setPersonalRotated] = useState(false);
	const [personalMovedUp, setPersonalMovedUp] = useState(false);
	const [personalExiting, setPersonalExiting] = useState(false);
	const [personalButtonsVisible, setPersonalButtonsVisible] = useState(false);
	const [openPanel, setOpenPanel] = useState<string | null>(null);
	const [openSubPanel, setOpenSubPanel] = useState<string | null>(null);
	const [entered, setEntered] = useState(false);
	const [clickColor, setClickColor] = useState<string | null>(null);
	const [clickPath, setClickPath] = useState<string | null>(null);
	const [showTiles, setShowTiles] = useState(false);
	const [user, setUser] = useState<SessionUser | null>(null);
	const [profileOpen, setProfileOpen] = useState(false);
	const enterTimer = useRef<ReturnType<typeof setTimeout>>();
	const profileRef = useRef<HTMLDivElement>(null);

	// Load user data on mount
	useEffect(() => {
		const stored = getUser();
		if (stored) {
			setUser(stored);
			return;
		}

		// Try to identify user from token by querying person data
		const token = getAccessToken();
		if (!token) return;

		// Decode token to get user_id (sub field)
		try {
			const payload = JSON.parse(atob(token.split('.')[1]));
			const userId = payload.sub;
			if (userId) {
				fetchCurrentUser(userId).then((data) => {
					if (data) {
						const newUser: SessionUser = {
							identificationNumber: userId,
							name: data.name,
							photoUrl: data.photoUrl,
						};
						saveUser(newUser);
						setUser(newUser);
					}
				}).catch(() => {});
			}
		} catch {}
	}, []);

	// Close profile dropdown on outside click
	useEffect(() => {
		function handleClick(e: MouseEvent) {
			if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
				setProfileOpen(false);
			}
		}
		if (profileOpen) {
			document.addEventListener('mousedown', handleClick);
			return () => document.removeEventListener('mousedown', handleClick);
		}
	}, [profileOpen]);

	useEffect(() => {
		if (navOpen) {
			setEntered(false);
			clearTimeout(enterTimer.current);
			enterTimer.current = setTimeout(() => setEntered(true), 500);
		} else {
			clearTimeout(enterTimer.current);
		}
		return () => clearTimeout(enterTimer.current);
	}, [navOpen]);

	useEffect(() => {
		if (expandedPersonal) {
			const t = setTimeout(() => setPersonalRotated(true), 500);
			return () => clearTimeout(t);
		} else {
			setPersonalRotated(false);
			setPersonalMovedUp(false);
			setPersonalExiting(false);
			setPersonalButtonsVisible(false);
			setOpenPanel(null);
			setOpenSubPanel(null);
		}
	}, [expandedPersonal]);

	useEffect(() => {
		if (personalRotated) {
			const t = setTimeout(() => setPersonalMovedUp(true), 500);
			return () => clearTimeout(t);
		} else {
			setPersonalMovedUp(false);
			setPersonalExiting(false);
		}
	}, [personalRotated]);

	useEffect(() => {
		if (personalMovedUp) {
			const t = setTimeout(() => setPersonalExiting(true), 500);
			return () => clearTimeout(t);
		} else {
			setPersonalExiting(false);
		}
	}, [personalMovedUp]);

	useEffect(() => {
		if (personalExiting) {
			const t2 = setTimeout(() => setPersonalButtonsVisible(true), 200);
			return () => { clearTimeout(t2); };
		} else if (!personalMovedUp) {
			setPersonalButtonsVisible(false);
		}
	}, [personalExiting]);

	useEffect(() => {
		if (!personalMovedUp) {
			setPersonalButtonsVisible(false);
		}
	}, [personalMovedUp]);

	const handleLogout = useCallback(async () => {
		const token = getAccessToken();
		const refreshToken = getRefreshToken();

		try {
			await graphql(
				`mutation Logout($token: String!, $refreshToken: String) {
					logout(token: $token, refresh_token: $refreshToken) { success }
				}`,
				{ token: token ?? '', refreshToken: refreshToken ?? null }
			);
		} catch {}

		clearSession();
		window.location.href = '/';
	}, []);

	const handleFolderClick = useCallback((e: React.MouseEvent, color: string, path: string, title: string) => {
		e.preventDefault();
		if (clickColor) return;

		if (title === 'Sistema' && !expandedPersonal) {
			setExpandedPersonal(true);
			return;
		}

		const folder = (e.currentTarget as HTMLElement).closest(`.${styles.folder}`) as HTMLElement;
		if (!folder) { window.location.href = path; return; }

		folder.style.zIndex = '9999';
		setClickColor(color);
		setClickPath(path);

		setTimeout(() => setShowTiles(true), 350);
	}, [clickColor, expandedPersonal]);

	const handleTilesComplete = useCallback(() => {
		if (clickPath) window.location.href = clickPath;
	}, [clickPath]);

	const avatarSrc = user?.photoUrl || DEFAULT_AVATAR;

	return (
		<>
			<nav className={styles.floatingNav}>
				<div className={styles.navLeft}>
					<button
						type="button"
						className={`${styles.iconBtn} ${navOpen ? styles.iconBtnActive : ''}`}
						onClick={() => setNavOpen((v) => !v)}
						aria-label="Menú de navegación"
					>
						<span className={styles.grid4}>
							<span /><span /><span /><span />
						</span>
					</button>
					<a href="/menu" className={styles.brandLink}>
						<img className={styles.brandLogo} src="/cajaIncasurLogo.jpg" alt="Incasur" />
					</a>
				</div>

				<div className={styles.profileWrap} ref={profileRef}>
					<button
						type="button"
						className={styles.profileBtn}
						onClick={() => setProfileOpen((v) => !v)}
						title="Perfil"
					>
						<img className={styles.profileImg} src={avatarSrc} alt="Perfil" />
					</button>

					<AnimatePresence>
						{profileOpen && (
							<motion.div
								className={styles.profileDropdown}
								initial={{ opacity: 0, y: -8, scale: 0.95 }}
								animate={{ opacity: 1, y: 0, scale: 1 }}
								exit={{ opacity: 0, y: -8, scale: 0.95 }}
								transition={{ duration: 0.15 }}
							>
								{user && (
									<div className={styles.profileInfo}>
										<strong>{user.name || 'Usuario'}</strong>
										<span>{user.identificationNumber}</span>
									</div>
								)}
								<button
									type="button"
									className={styles.logoutBtn}
									onClick={handleLogout}
								>
									<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
										<path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4" />
										<polyline points="16 17 21 12 16 7" />
										<line x1="21" y1="12" x2="9" y2="12" />
									</svg>
									Cerrar sesión
								</button>
							</motion.div>
						)}
					</AnimatePresence>
				</div>
			</nav>

			<AnimatePresence>
				{navOpen && !clickColor && (
					<motion.div
						key="folders-overlay"
						className={styles.foldersOverlay}
						initial={{ opacity: 0 }}
						animate={{ opacity: 1 }}
						exit={{ opacity: 0 }}
						transition={{ duration: 0.25 }}
					>
						<div className={styles.foldersStack}>
							{FOLDERS.map((folder, i) => {
								const offsetBase = (i + 1) * 36;
								const pushDown =
									hoveredFolder !== null && i < hoveredFolder ? 20 : 0;
								const offset = offsetBase - pushDown;
								const isPersonal = folder.title === 'Sistema';

								return (
									<motion.a
										key={folder.title}
										href={folder.path}
										className={`${styles.folder} ${isPersonal && expandedPersonal ? styles.folderFloated : ''} ${isPersonal && personalRotated ? styles.folderRotated : ''} ${isPersonal && personalMovedUp ? styles.folderMovedUp : ''}`}
										style={{
											zIndex: isPersonal && expandedPersonal ? 9999 : FOLDERS.length - i,
											background: folder.color,
											pointerEvents: expandedPersonal && !isPersonal ? 'none' : 'auto',
											opacity: expandedPersonal && !isPersonal ? 0.3 : undefined,
										}}
										initial={{ opacity: 0, bottom: offsetBase + 60 }}
										animate={{ opacity: 1, bottom: offset }}
										transition={
											entered
												? { duration: 0.3, ease: [0.22, 1, 0.36, 1] }
												: { delay: 0.06 * i, duration: 0.4, ease: [0.22, 1, 0.36, 1] }
										}
										onMouseEnter={() => setHoveredFolder(i)}
										onMouseLeave={() => setHoveredFolder(null)}
										onClick={(e) => { e.preventDefault(); e.stopPropagation(); if (!expandedPersonal) handleFolderClick(e, folder.color, folder.path, folder.title); }}
									>
										<div className={styles.folderTab} style={{ background: folder.color }}>
											{folder.title}
										</div>
									{isPersonal && (
										<div className={styles.folderBook}>
											<motion.div
												className={styles.folderCover}
												style={{ background: folder.color }}
												animate={personalExiting ? { rotateX: -180 } : { rotateX: 0 }}
												transition={{ duration: 0.6, ease: [0.22, 1, 0.36, 1] }}
											/>
										</div>
									)}
										{isPersonal && personalButtonsVisible && (
											<button
												type="button"
												className={styles.folderBack}
												onClick={(e) => { e.preventDefault(); e.stopPropagation(); setExpandedPersonal(false); }}
											>
												<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
													<polyline points="15 18 9 12 15 6" />
												</svg>
											</button>
										)}
										{isPersonal && personalButtonsVisible && (
											<div className={styles.folderButtons}>
												{SISTEMA_SUBOPTIONS.map((opt) => (
													<a
														key={opt.label}
														href="#"
														className={`${styles.subBtn} ${openPanel === opt.label ? styles.subBtnActive : ''}`}
														onClick={(e) => { e.preventDefault(); e.stopPropagation(); setOpenPanel((prev) => prev === opt.label ? null : opt.label); }}
													>
														{opt.label}
													</a>
												))}
											</div>
										)}
									</motion.a>
								);
							})}
						</div>
						<AnimatePresence>
							{openPanel && (
								<FolderPanel
									key={openPanel}
									label={openPanel}
									onClose={() => { setOpenPanel(null); setOpenSubPanel(null); }}
								>
									{openPanel === 'Roles y Permisos' && (
										<div className={styles.folderPanelLinks}>
											<SubPanelLink label="Asignar Permisos a un Role" onOpen={setOpenSubPanel} />
											<SubPanelLink label="Agregar Roles" onOpen={setOpenSubPanel} />
											<SubPanelLink label="Editar Roles" onOpen={setOpenSubPanel} />
										</div>
									)}
								</FolderPanel>
							)}
						</AnimatePresence>
						{openSubPanel === 'Editar Roles' && (
							<AssignPermissionsProvider>
								<FolderPanel key="roles-edit" label="Todos los Roles" onClose={() => setOpenSubPanel(null)} panelId="roles">
									<RolesPanel />
								</FolderPanel>
								<FolderPanel key="editar-role" label="Editar Role" onClose={() => setOpenSubPanel(null)} panelId="editarRole">
									<EditRolePanel />
								</FolderPanel>
							</AssignPermissionsProvider>
						)}
						{openSubPanel === 'Agregar Roles' && (
							<FolderPanel key="agregar-role" label="Agregar Role" onClose={() => setOpenSubPanel(null)} panelId="agregarRole">
								<AddRolePanel />
							</FolderPanel>
						)}
						{openSubPanel === 'Asignar Permisos a un Role' && (
							<AssignPermissionsProvider>
								<FolderPanel key="permisos" label="Todos los Permisos" onClose={() => setOpenSubPanel(null)} panelId="permisos">
									<PermissionsPanel />
								</FolderPanel>
								<FolderPanel key="roles" label="Todos los Roles" onClose={() => setOpenSubPanel(null)} panelId="roles">
									<RolesPanel />
								</FolderPanel>
								<FolderPanel key="asignar" label="Asignar Permisos a un Rol" onClose={() => setOpenSubPanel(null)} panelId="asignar">
									<AssignmentPanel />
								</FolderPanel>
							</AssignPermissionsProvider>
						)}
					</motion.div>
				)}
			</AnimatePresence>

			{showTiles && (
				<TileGrid color={clickColor || '#12667f'} onComplete={handleTilesComplete} />
			)}
		</>
	);
}

interface FolderPanelProps {
	label: string;
	onClose: () => void;
	children?: React.ReactNode;
	panelId?: string;
}

const PANEL_OFFSETS: Record<string, { x: number; y: number }> = {
	permisos: { x: -280, y: -60 },
	roles: { x: 20, y: -60 },
	asignar: { x: -130, y: 120 },
	agregarRole: { x: 60, y: 40 },
	editarRole: { x: 20, y: 140 },
};

function FolderPanel({ label, onClose, children, panelId }: FolderPanelProps) {
	const dragControls = useDragControls();
	const draggable = Boolean(panelId);
	const pos = useMemo(() => {
		const offset = panelId ? PANEL_OFFSETS[panelId] : null;
		if (offset) return offset;
		const spread = 180;
		return {
			x: -170 + (Math.random() - 0.5) * spread,
			y: -100 + (Math.random() - 0.5) * spread,
		};
	}, [panelId]);

	return (
		<motion.div
			className={`${styles.folderPanel} ${panelId ? styles.folderPanelIndependent : ''}`}
			initial={{ opacity: 0, scale: 0.9, x: pos.x, y: pos.y }}
			animate={{ opacity: 1, scale: 1, x: pos.x, y: pos.y }}
			exit={{ opacity: 0, scale: 0.85 }}
			transition={{ type: 'spring', stiffness: 300, damping: 25 }}
			drag={draggable}
			dragListener={false}
			dragControls={dragControls}
			dragMomentum={false}
			whileDrag={{ scale: 1.03 }}
		>
			<div
				className={styles.folderPanelHeader}
				style={draggable ? { cursor: 'grab', touchAction: 'none' } : undefined}
				onPointerDown={(e) => { if (draggable) dragControls.start(e); }}
			>
				<span className={styles.folderPanelLabel}>{label}</span>
				<button
					type="button"
					className={styles.folderPanelClose}
					onClick={(e) => { e.stopPropagation(); onClose(); }}
				>
					<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
						<line x1="18" y1="6" x2="6" y2="18" />
						<line x1="6" y1="6" x2="18" y2="18" />
					</svg>
				</button>
			</div>
			<div className={`${styles.folderPanelBody} ${panelId ? styles.folderPanelBodyIndependent : ''}`}>
				{children || <span>Contenido de {label}</span>}
			</div>
		</motion.div>
	);
}

interface SubPanelLinkProps {
	label: string;
	onOpen: (label: string) => void;
}

function SubPanelLink({ label, onOpen }: SubPanelLinkProps) {
	return (
		<button
			type="button"
			className={styles.subPanelLink}
			onClick={(e) => { e.preventDefault(); e.stopPropagation(); onOpen(label); }}
		>
			{label}
		</button>
	);
}

function TileGrid({ color, onComplete }: { color: string; onComplete: () => void }) {
	const done = useRef(0);
	const tile = 48;

	const tiles = useRef(
		(() => {
			const cols = Math.ceil(window.innerWidth / tile);
			const rows = Math.ceil(window.innerHeight / tile);
			return Array.from({ length: cols * rows }, (_, i) => ({
				x: (i % cols) * tile,
				y: Math.floor(i / cols) * tile,
				rotateX: (Math.random() - 0.5) * 200 + (Math.random() > 0.5 ? 180 : 0),
				rotateY: (Math.random() - 0.5) * 200,
				rotateZ: (Math.random() - 0.5) * 100,
				delay: Math.random() * 0.35,
				duration: 0.18 + Math.random() * 0.22,
			}));
		})()
	).current;

	const handleTileComplete = () => {
		done.current += 1;
		if (done.current >= tiles.length) onComplete();
	};

	return (
		<div style={{ position: 'fixed', inset: 0, zIndex: 9999, overflow: 'hidden' }}>
			{tiles.map((t, i) => (
				<motion.div
					key={i}
					style={{
						position: 'absolute',
						width: tile,
						height: tile,
						left: t.x,
						top: t.y,
						background: color,
						willChange: 'transform, opacity',
						backfaceVisibility: 'hidden',
					}}
					initial={{ scale: 0, rotateX: 0, rotateY: 0, rotateZ: 0, opacity: 1 }}
					animate={{ scale: 1, rotateX: t.rotateX, rotateY: t.rotateY, rotateZ: t.rotateZ, opacity: 1 }}
					transition={{ duration: t.duration, delay: t.delay, ease: [0.22, 1, 0.36, 1] }}
					onAnimationComplete={handleTileComplete}
				/>
			))}
		</div>
	);
}
