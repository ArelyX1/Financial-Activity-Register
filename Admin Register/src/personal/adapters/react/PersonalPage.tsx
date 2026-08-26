import { useState } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { AddPersonPanel } from './AddPerson';
import styles from './PersonalPage.module.css';

export default function PersonalPage() {
	const [showForm, setShowForm] = useState(false);

	return (
		<div className={styles.page}>
			<div className={styles.header}>
				<h1 className={styles.title}>Personal</h1>
				<button
					type="button"
					className={styles.addBtn}
					onClick={() => setShowForm(v => !v)}
				>
					<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round">
						{showForm ? (
							<line x1="18" y1="6" x2="6" y2="18" />
						) : (
							<>
								<line x1="12" y1="5" x2="12" y2="19" />
								<line x1="5" y1="12" x2="19" y2="12" />
							</>
						)}
					</svg>
					{showForm ? 'Cerrar' : 'Agregar Personal'}
				</button>
			</div>

			<AnimatePresence>
				{showForm && (
					<motion.div
						className={styles.formCard}
						initial={{ opacity: 0, y: 20 }}
						animate={{ opacity: 1, y: 0 }}
						exit={{ opacity: 0, y: 20 }}
						transition={{ duration: 0.25 }}
					>
						<div className={styles.cardHeader}>
							<span className={styles.cardTitle}>Nuevo Personal</span>
						</div>
						<div className={styles.cardBody}>
							<AddPersonPanel />
						</div>
					</motion.div>
				)}
			</AnimatePresence>

			{!showForm && (
				<div className={styles.emptyState}>
					<svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="#c4bfa8" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
						<path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2" />
						<circle cx="9" cy="7" r="4" />
						<path d="M23 21v-2a4 4 0 0 0-3-3.87" />
						<path d="M16 3.13a4 4 0 0 1 0 7.75" />
					</svg>
					<span>Pulse "Agregar Personal" para registrar nuevo personal</span>
				</div>
			)}
		</div>
	);
}
