import { useEffect, useState } from 'react';
import { motion } from 'motion/react';
import WindowTiles from '../../../ui/adapters/react/WindowTiles';
import FloatingNav from '../../../navigation/adapters/react/FloatingNav';
import styles from './Menu.module.css';

const LOGIN_BG = '#cfdc28';

const CHARTS = [
	{ label: 'Registros', value: 12, max: 20, color: '#12667f' },
	{ label: 'Usuarios', value: 45, max: 52, color: '#7a9c9c' },
	{ label: 'Ventas', value: 68, max: 100, color: '#c65b5b' },
	{ label: 'Alertas', value: 3, max: 10, color: '#daa520' },
];

const DONUT = [
	{ label: 'Completados', pct: 62, color: '#12667f' },
	{ label: 'Pendientes', pct: 25, color: '#daa520' },
	{ label: 'Revisión', pct: 13, color: '#c65b5b' },
];

export default function Menu() {
	const [intro, setIntro] = useState(true);

	useEffect(() => {
		document.body.style.background = '#f5f7fa';
		return () => { document.body.style.background = ''; };
	}, []);

	return (
		<div className={styles.layout}>
			<FloatingNav />

			<main className={styles.main}>
				<section className={styles.chartsGrid}>
					{CHARTS.map((c, i) => {
						const pct = (c.value / c.max) * 100;
						return (
							<motion.div
								key={c.label}
								className={styles.chartCard}
								initial={{ opacity: 0, y: 20 }}
								animate={{ opacity: 1, y: 0 }}
								transition={{ delay: 0.06 + i * 0.06, duration: 0.3 }}
							>
								<span className={styles.chartLabel}>{c.label}</span>
								<strong className={styles.chartValue}>{c.value}</strong>
								<div className={styles.barTrack}>
									<motion.div
										className={styles.barFill}
										style={{ background: c.color }}
										initial={{ width: 0 }}
										animate={{ width: `${pct}%` }}
										transition={{ delay: 0.2 + i * 0.08, duration: 0.7, ease: [0.22, 1, 0.36, 1] }}
									/>
								</div>
								<span className={styles.chartHint}>{c.value} / {c.max}</span>
							</motion.div>
						);
					})}
				</section>

				<section className={styles.donutSection}>
					<h2 className={styles.sectionTitle}>Distribución</h2>
					<div className={styles.donutRow}>
						<div className={styles.donutWrapper}>
							<svg viewBox="0 0 120 120" className={styles.donut}>
								{(() => {
									let acc = 0;
									return DONUT.map((seg) => {
										const dash = (seg.pct / 100) * 283;
										const offset = -(acc / 100) * 283;
										acc += seg.pct;
										return (
											<circle
												key={seg.label}
												cx="60" cy="60" r="45"
												fill="none"
												stroke={seg.color}
												strokeWidth="18"
												strokeDasharray={`${dash} ${283 - dash}`}
												strokeDashoffset={offset}
												style={{ transition: 'stroke-dasharray 0.8s ease' }}
											/>
										);
									});
								})()}
							</svg>
							<span className={styles.donutCenter}>100</span>
						</div>
						<div className={styles.donutLegend}>
							{DONUT.map((seg) => (
								<div key={seg.label} className={styles.legendItem}>
									<span className={styles.legendDot} style={{ background: seg.color }} />
									<span>{seg.label}</span>
									<strong>{seg.pct}%</strong>
								</div>
							))}
						</div>
					</div>
				</section>
			</main>

			{intro && <WindowTiles color={LOGIN_BG} mode="reveal" onComplete={() => setIntro(false)} />}
		</div>
	);
}
