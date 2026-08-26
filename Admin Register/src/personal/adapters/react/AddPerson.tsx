import { useState, useEffect, useCallback } from 'react';
import { motion, AnimatePresence } from 'motion/react';
import { graphql } from '../../../auth/api';
import { getAccessToken } from '../../../auth/session';
import styles from './AddPerson.module.css';

interface IdentificationType {
	id: number;
	name: string;
	code: string | null;
	country_iso: string;
	min_length: number;
	max_length: number;
	is_numeric: boolean | null;
	is_active: boolean | null;
}

interface Role {
	id: number;
	name: string;
	category: string;
	description: string | null;
	is_active: boolean | null;
}

export function AddPersonPanel() {
	const [idTypes, setIdTypes] = useState<IdentificationType[]>([]);
	const [roles, setRoles] = useState<Role[]>([]);
	const [loadingData, setLoadingData] = useState(true);
	const [errorData, setErrorData] = useState<string | null>(null);

	const [selectedIdType, setSelectedIdType] = useState<number | null>(null);
	const [identificationNumber, setIdentificationNumber] = useState('');
	const [roleCategory, setRoleCategory] = useState<string>('Employee');
	const [selectedRoles, setSelectedRoles] = useState<string[]>([]);
	const [submitting, setSubmitting] = useState(false);
	const [successMsg, setSuccessMsg] = useState<string | null>(null);

	useEffect(() => {
		const token = getAccessToken();
		if (!token) return;

		Promise.all([
			graphql<{ identification_types: IdentificationType[] }>(
				`query IdentificationTypes($token: String!) {
					identification_types(token: $token) {
						id name code country_iso min_length max_length is_numeric is_active
					}
				}`,
				{ token }
			),
			graphql<{ roles: Role[] }>(
				`query Roles {
					roles {
						id name category description is_active
					}
				}`,
				{}
			),
		])
			.then(([idData, roleData]) => {
				setIdTypes(idData.identification_types.filter(t => t.is_active !== false));
				setRoles(roleData.roles.filter(r => r.is_active !== false));
			})
			.catch(() => setErrorData('Error al cargar datos'))
			.finally(() => setLoadingData(false));
	}, []);

	const toggleRole = useCallback((roleName: string) => {
		setSelectedRoles(prev =>
			prev.includes(roleName) ? prev.filter(r => r !== roleName) : [...prev, roleName]
		);
	}, []);

	const filteredRoles = roles.filter(r => r.category === roleCategory);

	const canSubmit = selectedIdType !== null && identificationNumber.trim().length > 0 && selectedRoles.length > 0 && !submitting;

	const handleCreate = useCallback(async () => {
		if (!canSubmit) return;
		setSubmitting(true);
		try {
			const token = getAccessToken();
			await graphql<{ create_person: { id: string } }>(
				`mutation CreatePerson($input: CreatePersonInput!) {
					create_person(input: $input) { id }
				}`,
				{
					input: {
						id_identification_type: selectedIdType,
						identification_number: identificationNumber.trim(),
						role_names: selectedRoles,
					},
				}
			);
			setIdentificationNumber('');
			setSelectedRoles([]);
			setSuccessMsg('Personal creado correctamente');
			setTimeout(() => setSuccessMsg(null), 3000);
		} catch (e) {
			setSuccessMsg(null);
			alert(e instanceof Error ? e.message : 'Error al crear personal');
		} finally {
			setSubmitting(false);
		}
	}, [canSubmit, selectedIdType, identificationNumber, selectedRoles]);

	if (loadingData) {
		return (
			<div className={styles.loadingWrap}>
				<div className={styles.spinner} />
				<span>Cargando datos...</span>
			</div>
		);
	}

	if (errorData) {
		return (
			<div className={styles.errorWrap}>
				<span>{errorData}</span>
				<button type="button" className={styles.retryBtn} onClick={() => window.location.reload()}>Reintentar</button>
			</div>
		);
	}

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
					<label className={styles.formLabel}>Tipo de documento *</label>
					<select
						value={selectedIdType ?? ''}
						onChange={e => setSelectedIdType(Number(e.target.value) || null)}
						className={`${styles.searchInput} ${styles.selectField}`}
					>
						<option value="">Seleccionar...</option>
						{idTypes.map(t => (
							<option key={t.id} value={t.id}>{t.name}</option>
						))}
					</select>
				</div>

				<div className={styles.formGroup}>
					<label className={styles.formLabel}>Documento de identidad *</label>
					<input
						type="text"
						placeholder="Ingrese número de documento"
						maxLength={30}
						value={identificationNumber}
						onChange={e => setIdentificationNumber(e.target.value)}
						className={styles.searchInput}
					/>
				</div>

				<div className={styles.formGroup}>
					<label className={styles.formLabel}>Roles *</label>
					<div className={styles.categoryTabs}>
						{['Employee', 'Client'].map(cat => (
							<button
								type="button"
								key={cat}
								className={`${styles.categoryTab} ${roleCategory === cat ? styles.categoryTabActive : ''}`}
								onClick={() => setRoleCategory(cat)}
							>
								{cat === 'Employee' ? 'Empleado' : 'Cliente'}
							</button>
						))}
					</div>
					{selectedRoles.length > 0 && (
						<div className={styles.selectedPermsWrap}>
							{selectedRoles.map(name => (
								<span key={name} className={styles.permTag}>
									{name}
									<button type="button" className={styles.removeTag} onClick={() => toggleRole(name)}>
										<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/></svg>
									</button>
								</span>
							))}
						</div>
					)}
					{filteredRoles.length === 0 ? (
						<span className={styles.noSelection}>No hay roles disponibles</span>
					) : (
						<div className={styles.roleList}>
							{filteredRoles.map(role => (
								<button
									type="button"
									key={role.id}
									className={`${styles.roleItem} ${selectedRoles.includes(role.name) ? styles.roleItemSelected : ''}`}
									onClick={() => toggleRole(role.name)}
								>
									<span className={`${styles.checkbox} ${selectedRoles.includes(role.name) ? styles.checked : ''}`}>
										{selectedRoles.includes(role.name) && (
											<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12"/></svg>
										)}
									</span>
									<div className={styles.roleInfo}>
										<span className={styles.roleName}>{role.name}</span>
										<span className={styles.roleCategory}>{role.category}</span>
									</div>
								</button>
							))}
						</div>
					)}
				</div>
			</div>

			<div className={styles.panelFooter}>
				<button
					type="button"
					className={`${styles.assignBtn} ${!canSubmit ? styles.assignBtnDisabled : ''}`}
					disabled={!canSubmit}
					onClick={handleCreate}
				>
					{submitting ? <span className={styles.confirmSpinner} /> : 'Crear Personal'}
				</button>
			</div>
		</div>
	);
}
