import { useState, useCallback } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { graphql } from '../../../auth/api';
import { getAccessToken } from '../../../auth/session';
import styles from './AssignPermissions.module.css';

export function AddRolePanel() {
	const [name, setName] = useState('');
	const [category, setCategory] = useState('');
	const [description, setDescription] = useState('');
	const [isSystemRole, setIsSystemRole] = useState(false);
	const [isActive, setIsActive] = useState(true);
	const [submitting, setSubmitting] = useState(false);
	const [successMsg, setSuccessMsg] = useState<string | null>(null);

	const canSubmit = name.trim().length > 0 && category.trim().length > 0 && !submitting;

	const handleCreate = useCallback(async () => {
		if (!canSubmit) return;
		setSubmitting(true);
		try {
			const token = getAccessToken();
			await graphql<{ create_role: { id: number } }>(
				`mutation CreateRole($token: String!, $input: CreateRoleInput!) {
					create_role(token: $token, input: $input) {
						id name
					}
				}`,
				{
					token,
					input: {
						name: name.trim(),
						category: category.trim(),
						description: description.trim() || null,
						is_system_role: isSystemRole,
						is_active: isActive,
					},
				}
			);
			setName('');
			setCategory('');
			setDescription('');
			setIsSystemRole(false);
			setIsActive(true);
			setSuccessMsg('Rol creado correctamente');
			setTimeout(() => setSuccessMsg(null), 3000);
		} catch (e) {
			setSuccessMsg(null);
			alert(e instanceof Error ? e.message : 'Error al crear el rol');
		} finally {
			setSubmitting(false);
		}
	}, [canSubmit, name, category, description, isSystemRole, isActive]);

	return (
		<div className={styles.panelInner}>
			<AnimatePresence>
				{successMsg && (
					<motion.div className={styles.toast} initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }}>
						{successMsg}
					</motion.div>
				)}
			</AnimatePresence>

			<div className={styles.panelBody}>
				<div className={styles.formGroup}>
					<label className={styles.formLabel}>Nombre *</label>
					<input type="text" placeholder="Ej. Cajero" maxLength={50} value={name} onChange={e => setName(e.target.value)} className={styles.searchInput} />
				</div>

				<div className={styles.formGroup}>
					<label className={styles.formLabel}>Categoría *</label>
					<select value={category} onChange={e => setCategory(e.target.value)} className={`${styles.searchInput} ${styles.selectField}`}>
						<option value="">Seleccionar...</option>
						<option value="Employee">Employee</option>
						<option value="Client">Client</option>
					</select>
				</div>

				<div className={styles.formGroup}>
					<label className={styles.formLabel}>Descripción</label>
					<textarea placeholder="Descripción del rol (opcional)" value={description} onChange={e => setDescription(e.target.value)} className={styles.searchInput} rows={3} />
				</div>

				<button type="button" className={styles.checkboxRow} onClick={() => setIsSystemRole(v => !v)}>
					<span className={`${styles.checkbox} ${isSystemRole ? styles.checked : ''}`}>
						{isSystemRole && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>}
					</span>
					Rol de sistema
				</button>

				<button type="button" className={styles.checkboxRow} onClick={() => setIsActive(v => !v)}>
					<span className={`${styles.checkbox} ${isActive ? styles.checked : ''}`}>
						{isActive && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>}
					</span>
					Activo
				</button>
			</div>

			<div className={styles.panelFooter}>
				<button
					type="button"
					className={`${styles.assignBtn} ${!canSubmit ? styles.assignBtnDisabled : ''}`}
					disabled={!canSubmit}
					onClick={handleCreate}
				>
					{submitting ? <span className={styles.confirmSpinner} /> : 'Crear Rol'}
				</button>
			</div>
		</div>
	);
}
