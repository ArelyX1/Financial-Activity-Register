import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { clearSession } from '../../../auth/session';
import styles from './FloatingNav.module.css';

const FOLDERS = [
	{ title: 'Folder 1', color: '#12667f' },
	{ title: 'Folder 2', color: '#7a9c9c' },
	{ title: 'Folder 3', color: '#c65b5b' },
];

export default function FloatingNav() {
	const [navOpen, setNavOpen] = useState(false);
	const [hoveredFolder, setHoveredFolder] = useState<number | null>(null);

	const handleLogout = () => {
		clearSession();
		window.location.href = '/';
	};

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
				<button type="button" className={styles.profileBtn} onClick={handleLogout} title="Cerrar sesión">
					<img className={styles.profileImg} src="/cajaIncasurLogo.jpg" alt="Perfil" />
				</button>
			</nav>

			<AnimatePresence>
				{navOpen && (
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
								const rev = FOLDERS.length - 1 - i;
								const baseY = rev * 36;
								const pushDown =
									hoveredFolder !== null && hoveredFolder < i ? 22 : 0;
								const y = baseY + pushDown;
								const z = i + 1;

								return (
									<motion.div
										key={folder.title}
										className={styles.folder}
										style={{
											top: y,
											zIndex: z,
											background: folder.color,
										}}
										initial={{ opacity: 0, top: baseY + 60 }}
										animate={{ opacity: 1, top: y }}
										transition={{
											delay: 0.06 * rev,
											duration: 0.4,
											ease: [0.22, 1, 0.36, 1],
										}}
										onMouseEnter={() => setHoveredFolder(i)}
										onMouseLeave={() => setHoveredFolder(null)}
									>
										<div
											className={styles.folderTab}
											style={{ background: folder.color }}
										>
											{folder.title}
										</div>
									</motion.div>
								);
							})}
						</div>
					</motion.div>
				)}
			</AnimatePresence>
		</>
	);
}
