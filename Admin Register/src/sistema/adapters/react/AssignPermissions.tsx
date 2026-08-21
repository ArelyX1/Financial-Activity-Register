import { useState, useEffect, useCallback, useMemo, createContext, useContext, type ReactNode } from 'react';
import { createPortal } from 'react-dom';
import { motion, AnimatePresence } from 'motion/react';
import { graphql } from '../../../auth/api';
import { getAccessToken } from '../../../auth/session';
import styles from './AssignPermissions.module.css';

interface Permission {
	id: number;
	code: string;
	name: string;
	description: string | null;
	module: string | null;
	is_active: boolean | null;
	created_at: string | null;
}

interface Role {
	id: number;
	name: string;
	description: string | null;
	category: string | null;
	is_system_role: boolean | null;
	is_active: boolean | null;
	created_at: string | null;
	permissions: { code: string }[];
}

interface AssignCtx {
	permissions: Permission[];
	roles: Role[];
	loading: boolean;
	error: string | null;
	modules: string[];
	permissionsByModule: Map<string, Permission[]>;
	selectedRoleId: number | null;
	setSelectedRoleId: (id: number | null) => void;
	selectRole: (id: number | null) => void;
	reloadRoles: () => Promise<void>;
	hasChanges: boolean;
	selectedCodes: Set<string>;
	togglePerm: (code: string) => void;
	toggleModule: (mod: string) => void;
	selectAllPerms: () => void;
	searchRole: string;
	setSearchRole: (v: string) => void;
	searchPerm: string;
	setSearchPerm: (v: string) => void;
}

const Ctx = createContext<AssignCtx | null>(null);

const PERMISSIONS_QUERY = `
  query QueryPermissions {
    query_permissions {
      id code name description module is_active created_at
    }
  }
`;

const ROLES_QUERY = `
  query Roles {
    roles {
      id name description category is_system_role is_active created_at
      permissions { code }
    }
  }
`;

export function AssignPermissionsProvider({ children }: { children: ReactNode }) {
	const [permissions, setPermissions] = useState<Permission[]>([]);
	const [roles, setRoles] = useState<Role[]>([]);
	const [loading, setLoading] = useState(true);
	const [error, setError] = useState<string | null>(null);
	const [selectedRoleId, setSelectedRoleId] = useState<number | null>(null);
	const [selectedCodes, setSelectedCodes] = useState<Set<string>>(new Set());
	const [searchRole, setSearchRole] = useState('');
	const [searchPerm, setSearchPerm] = useState('');

	useEffect(() => {
		let cancelled = false;
		(async () => {
			try {
				const [permData, roleData] = await Promise.all([
					graphql<{ query_permissions: Permission[] }>(PERMISSIONS_QUERY, {}),
					graphql<{ roles: Role[] }>(ROLES_QUERY, {}),
				]);
				if (!cancelled) {
					setPermissions(permData.query_permissions);
					setRoles(roleData.roles);
				}
			} catch (e) {
				if (!cancelled) setError(e instanceof Error ? e.message : 'Error al cargar datos');
			} finally {
				if (!cancelled) setLoading(false);
			}
		})();
		return () => { cancelled = true; };
	}, []);

	const permissionsByModule = useMemo(() => {
		const map = new Map<string, Permission[]>();
		const q = searchPerm.toLowerCase();
		permissions.forEach(p => {
			if (q && !p.code.toLowerCase().includes(q) && !p.name.toLowerCase().includes(q) && !(p.module || '').toLowerCase().includes(q)) return;
			const mod = p.module || 'Sin módulo';
			if (!map.has(mod)) map.set(mod, []);
			map.get(mod)!.push(p);
		});
		return map;
	}, [permissions, searchPerm]);

	const modules = useMemo(() => Array.from(permissionsByModule.keys()).sort(), [permissionsByModule]);

	const selectRole = useCallback((id: number | null) => {
		setSelectedRoleId(id);
		const role = id == null ? undefined : roles.find(r => r.id === id);
		setSelectedCodes(new Set((role?.permissions ?? []).map(p => p.code)));
	}, [roles]);

	const reloadRoles = useCallback(async () => {
		try {
			const roleData = await graphql<{ roles: Role[] }>(ROLES_QUERY, {});
			setRoles(roleData.roles);
		} catch {}
	}, []);

	const originalCodes = useMemo(() => {
		const role = roles.find(r => r.id === selectedRoleId);
		return new Set((role?.permissions ?? []).map(p => p.code));
	}, [roles, selectedRoleId]);

	const hasChanges = useMemo(() => {
		if (!selectedRoleId) return false;
		if (selectedCodes.size !== originalCodes.size) return true;
		for (const c of originalCodes) {
			if (!selectedCodes.has(c)) return true;
		}
		return false;
	}, [selectedRoleId, selectedCodes, originalCodes]);

	const togglePerm = useCallback((code: string) => {
		setSelectedCodes(prev => {
			const next = new Set(prev);
			if (next.has(code)) next.delete(code);
			else next.add(code);
			return next;
		});
	}, []);

	const toggleModule = useCallback((mod: string) => {
		const modPerms = (permissionsByModule.get(mod) || []).map(p => p.code);
		setSelectedCodes(prev => {
			const next = new Set(prev);
			const allSelected = modPerms.every(c => next.has(c));
			if (allSelected) modPerms.forEach(c => next.delete(c));
			else modPerms.forEach(c => next.add(c));
			return next;
		});
	}, [permissionsByModule]);

	const selectAllPerms = useCallback(() => {
		setSelectedCodes(prev => {
			if (prev.size === permissions.length) return new Set();
			return new Set(permissions.map(p => p.code));
		});
	}, [permissions]);

	const value: AssignCtx = useMemo(() => ({
		permissions, roles, loading, error,
		modules, permissionsByModule,
		selectedRoleId, setSelectedRoleId, selectRole, reloadRoles, hasChanges,
		selectedCodes, togglePerm, toggleModule, selectAllPerms,
		searchRole, setSearchRole, searchPerm, setSearchPerm,
	}), [permissions, roles, loading, error, modules, permissionsByModule, selectedRoleId, selectRole, reloadRoles, hasChanges, selectedCodes, togglePerm, toggleModule, selectAllPerms, searchRole, searchPerm]);

	return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useAssignCtx() {
	const ctx = useContext(Ctx);
	if (!ctx) throw new Error('AssignPermissionsProvider missing');
	return ctx;
}

/* ================================================================
   Panel 1 — Todos los Permisos
   ================================================================ */

export function PermissionsPanel() {
	const { permissions, modules, permissionsByModule, selectedCodes, togglePerm, toggleModule, selectAllPerms, searchPerm, setSearchPerm, loading, error } = useAssignCtx();

	if (loading) return <PanelLoading />;
	if (error) return <PanelError message={error} />;

	return (
		<div className={styles.panelInner}>
			<div className={styles.panelSearch}>
				<input type="text" placeholder="Buscar permisos..." value={searchPerm} onChange={e => setSearchPerm(e.target.value)} className={styles.searchInput} />
			</div>
			<div className={styles.panelBody}>
				{modules.length === 0 && <p className={styles.emptyText}>No hay módulos</p>}
				{modules.map(mod => {
					const modPerms = permissionsByModule.get(mod) || [];
					if (modPerms.length === 0) return null;
					const allSelected = modPerms.every(p => selectedCodes.has(p.code));
					return (
						<div key={mod} className={styles.moduleGroup}>
							<div className={styles.moduleHeader}>
								<button type="button" className={styles.moduleCheck} onClick={() => toggleModule(mod)}>
									<span className={`${styles.checkbox} ${allSelected ? styles.checked : ''}`}>
										{allSelected && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>}
									</span>
								</button>
								<button type="button" className={styles.moduleToggle} onClick={() => toggleModule(mod)}>{mod}</button>
								<span className={styles.moduleCount}>{modPerms.filter(p => selectedCodes.has(p.code)).length}/{modPerms.length}</span>
							</div>
							<div className={styles.permList}>
								{modPerms.map(p => (
									<motion.button key={p.code} type="button" className={`${styles.permItem} ${selectedCodes.has(p.code) ? styles.permItemSelected : ''}`} onClick={() => togglePerm(p.code)} whileHover={{ x: 2 }} transition={{ type: 'spring', stiffness: 400, damping: 25 }}>
										<span className={`${styles.checkbox} ${selectedCodes.has(p.code) ? styles.checked : ''}`}>
											{selectedCodes.has(p.code) && <svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>}
										</span>
										<div className={styles.permInfo}>
											<span className={styles.permCode}>{p.code}</span>
											<span className={styles.permName}>{p.name}</span>
										</div>
										<span className={`${styles.permBadge} ${p.is_active ? styles.badgeActive : styles.badgeInactive}`}>
											{p.is_active ? 'Activo' : 'Inactivo'}
										</span>
									</motion.button>
								))}
							</div>
						</div>
					);
				})}
			</div>
			<div className={styles.panelFooter}>
				<button type="button" className={styles.selectAllBtn} onClick={selectAllPerms}>
					{selectedCodes.size === permissions.length ? 'Deseleccionar todo' : 'Seleccionar todo'}
				</button>
				<span className={styles.selectionCount}>{selectedCodes.size} seleccionados</span>
			</div>
		</div>
	);
}

/* ================================================================
   Panel 2 — Todos los Roles
   ================================================================ */

export function RolesPanel() {
	const { roles, selectedRoleId, selectRole, searchRole, setSearchRole, loading, error } = useAssignCtx();
	const [showFilters, setShowFilters] = useState(false);
	const [statusFilter, setStatusFilter] = useState<'todos' | 'activos' | 'inactivos'>('todos');
	const [categoryFilter, setCategoryFilter] = useState('todas');

	const filteredRoles = useMemo(() => {
		const q = searchRole.toLowerCase();
		return roles
			.filter(r => {
				const matchesSearch =
					!q ||
					r.name.toLowerCase().includes(q) ||
					(r.description || '').toLowerCase().includes(q) ||
					(r.category || '').toLowerCase().includes(q);
				if (!matchesSearch) return false;
				if (statusFilter === 'activos' && !r.is_active) return false;
				if (statusFilter === 'inactivos' && r.is_active) return false;
				if (categoryFilter !== 'todas' && (r.category || '') !== categoryFilter) return false;
				return true;
			})
			.sort((a, b) => {
				if (Boolean(a.is_active) !== Boolean(b.is_active)) return a.is_active ? -1 : 1;
				return a.name.localeCompare(b.name);
			});
	}, [roles, searchRole, statusFilter, categoryFilter]);

	if (loading) return <PanelLoading />;
	if (error) return <PanelError message={error} />;

	return (
		<div className={styles.panelInner}>
			<div className={styles.panelSearch}>
				<input type="text" placeholder="Buscar roles..." value={searchRole} onChange={e => setSearchRole(e.target.value)} className={styles.searchInput} />
				<button
					type="button"
					className={`${styles.filterBtn} ${showFilters ? styles.filterBtnActive : ''}`}
					onClick={() => setShowFilters(v => !v)}
					title="Filtros"
				>
					<svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polygon points="22 3 2 3 10 12.46 10 19 14 21 14 12.46 22 3" /></svg>
				</button>
			</div>
			{showFilters && (
				<div className={styles.filterBar}>
					<label className={styles.filterGroup}>
						Estado
						<select value={statusFilter} onChange={e => setStatusFilter(e.target.value as typeof statusFilter)} className={`${styles.searchInput} ${styles.selectField}`}>
							<option value="todos">Todos</option>
							<option value="activos">Activos</option>
							<option value="inactivos">Inactivos</option>
						</select>
					</label>
					<label className={styles.filterGroup}>
						Categoría
						<select value={categoryFilter} onChange={e => setCategoryFilter(e.target.value)} className={`${styles.searchInput} ${styles.selectField}`}>
							<option value="todas">Todas</option>
							<option value="Employee">Employee</option>
							<option value="Client">Client</option>
						</select>
					</label>
				</div>
			)}
			<div className={styles.panelBody}>
				{filteredRoles.length === 0 && <p className={styles.emptyText}>No se encontraron roles</p>}
				{filteredRoles.map(r => (
					<motion.div
						key={r.id}
						className={`${styles.roleItem} ${selectedRoleId === r.id ? styles.roleItemSelected : ''}`}
						onClick={() => selectRole(r.id === selectedRoleId ? null : r.id)}
						whileHover={{ x: 2 }}
						transition={{ type: 'spring', stiffness: 400, damping: 25 }}
					>
						<div className={styles.roleMain}>
							<span className={styles.roleName}>{r.name}</span>
							{r.category && <span className={styles.roleCategory}>{r.category}</span>}
						</div>
						{r.description && <span className={styles.roleDesc}>{r.description}</span>}
						<div className={styles.roleMeta}>
							<span className={`${styles.permBadge} ${r.is_active ? styles.badgeActive : styles.badgeInactive}`}>
								{r.is_active ? 'Activo' : 'Inactivo'}
							</span>
							{r.is_system_role && <span className={styles.systemBadge}>Sistema</span>}
							<span className={styles.permCount}>{r.permissions.length} permisos</span>
							{r.created_at && <span className={styles.dateText}>{new Date(r.created_at).toLocaleDateString()}</span>}
						</div>
					</motion.div>
				))}
			</div>
		</div>
	);
}

/* ================================================================
   Panel 3 — Asignar Permisos a un Rol
   ================================================================ */

export function AssignmentPanel() {
	const { roles, permissions, selectedRoleId, selectRole, selectedCodes, togglePerm, reloadRoles, hasChanges, loading, error } = useAssignCtx();
	const [showConfirm, setShowConfirm] = useState(false);
	const [submitting, setSubmitting] = useState(false);
	const [successMsg, setSuccessMsg] = useState<string | null>(null);

	const selectedRole = useMemo(() => roles.find(r => r.id === selectedRoleId), [roles, selectedRoleId]);

	const handleAssign = useCallback(async () => {
		if (!selectedRoleId) return;
		setSubmitting(true);
		try {
			const token = getAccessToken();
			await graphql<{ assign_role_permissions: { id: number } }>(
				`mutation AssignRolePermissions($token: String!, $input: AssignRolePermissionsInput!) {
					assign_role_permissions(token: $token, input: $input) {
						id name
						permissions { code }
					}
				}`,
				{ token, input: { role_id: selectedRoleId, permission_codes: Array.from(selectedCodes) } }
			);
			setShowConfirm(false);
			setSuccessMsg('Permisos asignados correctamente');
			setTimeout(() => setSuccessMsg(null), 3000);
			await reloadRoles();
		} catch (e) {
			setSuccessMsg(null);
			alert(e instanceof Error ? e.message : 'Error al asignar permisos');
		} finally {
			setSubmitting(false);
		}
	}, [selectedRoleId, selectedCodes, reloadRoles]);

	if (loading) return <PanelLoading />;
	if (error) return <PanelError message={error} />;

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
					<label className={styles.formLabel}>Rol seleccionado</label>
					{selectedRole ? (
						<div className={styles.selectedRoleTag}>
							<span>{selectedRole.name}</span>
							<button type="button" className={styles.removeTag} onClick={() => selectRole(null)}>
								<svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
							</button>
						</div>
					) : (
						<span className={styles.noSelection}>Ningún rol seleccionado — haz clic en un rol en el panel de Roles</span>
					)}
				</div>

				<div className={styles.formGroup}>
					<label className={styles.formLabel}>
						Permisos seleccionados
						<span className={styles.selectionBadge}>{selectedCodes.size}</span>
					</label>
					{selectedCodes.size === 0 ? (
						<span className={styles.noSelection}>Ningún permiso seleccionado — marca permisos en el panel de Permisos</span>
					) : (
						<div className={styles.selectedPermsWrap}>
							{Array.from(selectedCodes).map(code => {
								const perm = permissions.find(p => p.code === code);
								return (
									<motion.span key={code} className={styles.permTag} initial={{ scale: 0 }} animate={{ scale: 1 }} exit={{ scale: 0 }}>
										{perm ? perm.name : code}
										<button type="button" className={styles.removeTag} onClick={() => togglePerm(code)}>
											<svg width="10" height="10" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round" strokeLinejoin="round"><line x1="18" y1="6" x2="6" y2="18" /><line x1="6" y1="6" x2="18" y2="18" /></svg>
										</button>
									</motion.span>
								);
							})}
						</div>
					)}
				</div>
			</div>

			<div className={styles.panelFooter}>
				<button type="button" className={styles.cancelBtn} onClick={() => selectRole(null)}>
					Cancelar
				</button>
				<button
					type="button"
					className={`${styles.assignBtn} ${(!selectedRoleId || !hasChanges) ? styles.assignBtnDisabled : ''}`}
					disabled={!selectedRoleId || !hasChanges}
					onClick={() => setShowConfirm(true)}
				>
					Asignar Permisos
				</button>
			</div>

			{createPortal(
				<AnimatePresence>
					{showConfirm && (
						<motion.div className={styles.confirmOverlay} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => !submitting && setShowConfirm(false)}>
						<motion.div className={styles.confirmModal} initial={{ scale: 0.85, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.85, opacity: 0 }} transition={{ type: 'spring', stiffness: 400, damping: 30 }} onClick={e => e.stopPropagation()}>
							<div className={styles.confirmHeader}>
								<div className={styles.confirmIcon}>
									<svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" /><line x1="12" y1="9" x2="12" y2="13" /><line x1="12" y1="17" x2="12.01" y2="17" /></svg>
								</div>
								<h3 className={styles.confirmTitle}>Confirmar cambios</h3>
								<p className={styles.confirmSubtitle}>Se asignarán los siguientes permisos al rol seleccionado</p>
							</div>
							<div className={styles.confirmBody}>
								<div className={styles.confirmSummary}>
									<div className={styles.confirmRow}>
										<span className={styles.confirmLabel}>Rol:</span>
										<span className={styles.confirmValue}>{selectedRole?.name}</span>
									</div>
									<div className={styles.confirmDivider} />
									<div className={styles.confirmRow}>
										<span className={styles.confirmLabel}>Permisos ({selectedCodes.size}):</span>
									</div>
									<div className={styles.confirmPermsList}>
										{Array.from(selectedCodes).map(code => {
											const perm = permissions.find(p => p.code === code);
											return (
												<div key={code} className={styles.confirmPermItem}>
													<span className={styles.confirmPermCode}>{code}</span>
													<span className={styles.confirmPermName}>{perm?.name || code}</span>
												</div>
											);
										})}
									</div>
								</div>
							</div>
							<div className={styles.confirmActions}>
								<button type="button" className={styles.confirmCancelBtn} onClick={() => setShowConfirm(false)} disabled={submitting}>Cancelar</button>
								<button type="button" className={`${styles.confirmAssignBtn} ${submitting ? styles.confirmAssignBtnLoading : ''}`} onClick={handleAssign} disabled={submitting}>
									{submitting ? <span className={styles.confirmSpinner} /> : <><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round" strokeLinejoin="round"><polyline points="20 6 9 17 4 12" /></svg>Confirmar</>}
								</button>
							</div>
						</motion.div>
					</motion.div>
				)}
				</AnimatePresence>,
				document.body
			)}
		</div>
	);
}

/* ================================================================
   Shared tiny components
   ================================================================ */

function PanelLoading() {
	return (
		<div className={styles.loadingWrap}>
			<motion.div className={styles.spinner} animate={{ rotate: 360 }} transition={{ repeat: Infinity, duration: 0.8, ease: 'linear' }} />
			<span>Cargando...</span>
		</div>
	);
}

function PanelError({ message }: { message: string }) {
	return (
		<div className={styles.errorWrap}>
			<span>{message}</span>
		</div>
	);
}
