import { useState, useEffect, useCallback, useMemo } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { graphql } from '../../../auth/api';
import { getAccessToken } from '../../../auth/session';
import { useAssignCtx } from './AssignPermissions';
import styles from './AssignPermissions.module.css';

export function EditRolePanel() {
	const { roles, selectedRoleId, reloadRoles, selectRole } = useAssignCtx();
	const role = useMemo(() => roles.find(r => r.id === selectedRoleId) ?? null, [roles, selectedRoleId]);

	const [name, setName] = useState('');
	const [category, setCategory] = useState('');
	const [description, setDescription] = useState('');
	const [isSystemRole, setIsSystemRole] = useState(false);
	const [isActive, setIsActive] = useState(true);
	const [submitting, setSubmitting] = useState(false);
	const [successMsg, setSuccessMsg] = useState<string | null>(null);

	useEffect(() => {
		if (!role) return;
		setName(role.name);
		setCategory(role.category || '');
		setDescription(role.description || '');
		setIsSystemRole(Boolean(role.is_system_role));
		setIsActive(Boolean(role.is_active));
	}, [role?.id]);

	const hasChanges = useMemo(() => {
		if (!role) return false;
		return (
			name !== (role.name ?? '') ||
			category !== (role.category || '') ||
			description !== (role.description || '') ||
			isSystemRole !== Boolean(role.is_system_role) ||
			isActive !== Boolean(role.is_active)
		);
	}, [role, name, category, description, isSystemRole, isActive]);

	const canSave = Boolean(role) && hasChanges && name.trim().length > 0 && category.trim().length > 0 && !submitting;

	const handleSave = useCallback(async () => {
		if (!role || !canSave) return;
		setSubmitting(true);
		try {
			const token = getAccessToken();
			await graphql<{ update_role: { id: number } }>(
				`mutation UpdateRole($token: String!, $roleId: Int!, $input: UpdateRoleInput!) {
					update_role(token: $token, role_id: $roleId, input: $input) {
						id name
					}
				}`,
				{
					token,
					roleId: role.id,
					input: {
						name: name.trim(),
						category: category.trim(),
						description: description.trim() || null,
						is_system_role: isSystemRole,
						is_active: isActive,
					},
				}
			);
			await reloadRoles();
			setSuccessMsg(isActive ? 'Rol actualizado correctamente' : 'Rol desactivado correctamente');
			setTimeout(() => setSuccessMsg(null), 3000);
		} catch (e) {
			setSuccessMsg(null);
			alert(e instanceof Error ? e.message : 'Error al actualizar el rol');
		} finally {
			setSubmitting(false);
		}
	}, [role, canSave, name, category, description, isSystemRole, isActive, reloadRoles]);

	return (
		<div className={styles.panelInner}>
			<AnimatePresence>
				{successMsg && (
					<motion.div className={styles.toast} initial={{ opacity: 0, y: -20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -20 }}>
						{successMsg}
					</motion.div>
				)}
			</AnimatePresence>

			{!role ? (
				<div className={styles.panelBody}>
					<span className={styles.noSelection}>Ningún rol seleccionado — haz clic en un rol en el panel de Roles</span>
				</div>
			) : (
				<>
					<div className={styles.panelBody}>
						<div className={styles.formGroup}>
							<label className={styles.formLabel}>Nombre *</label>
							<input type="text" placeholder="Nombre del rol" maxLength={50} value={name} onChange={e => setName(e.target.value)} className={styles.searchInput} />
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
							<textarea placeholder="Descripción del rol" value={description} onChange={e => setDescription(e.target.value)} className={styles.searchInput} rows={3} />
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
							{isActive ? 'Activo (clic para desactivar)' : 'Inactivo (clic para activar)'}
						</button>
					</div>

					<div className={styles.panelFooter}>
						<button type="button" className={styles.cancelBtn} onClick={() => selectRole(null)}>
							Deseleccionar
						</button>
						<button
							type="button"
							className={`${styles.assignBtn} ${!canSave ? styles.assignBtnDisabled : ''}`}
							disabled={!canSave}
							onClick={handleSave}
						>
							{submitting ? <span className={styles.confirmSpinner} /> : 'Guardar Cambios'}
						</button>
					</div>
				</>
			)}
		</div>
	);
}
