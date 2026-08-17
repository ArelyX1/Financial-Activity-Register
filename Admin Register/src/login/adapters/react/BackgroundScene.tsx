import { useRef } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Float, Sparkles } from '@react-three/drei';
import type { Group, Mesh } from 'three';

const SECONDARY = '#12667f';
const TERTIARY = '#c65b5b';
const ACCENT = '#4a4a4a';
const ACCENT3 = '#7a9c9c';
const ACCENT4 = '#adb5bd';
const WARNING = '#daa520';
const SUCCESS = '#329b47';

type ShapeKind =
	| 'torus'
	| 'icosa'
	| 'knot'
	| 'sphere'
	| 'octa'
	| 'box'
	| 'cone'
	| 'cylinder'
	| 'dodeca'
	| 'tetra';

interface ShapeSpec {
	position: [number, number, number];
	scale: number;
	color: string;
	kind: ShapeKind;
	speed?: number;
	spin?: number;
	opacity?: number;
	detail?: [number, number, number];
}

const SHAPES: ShapeSpec[] = [
	// Anillo central (profundidad)
	{ position: [0, 0, -8], scale: 2.6, color: SECONDARY, kind: 'torus', opacity: 0.22, spin: 0.04, detail: [3, 0.12, 24] },

	// Capa cercana
	{ position: [-2.8, 1.5, -1], scale: 1, color: SECONDARY, kind: 'torus', opacity: 0.5 },
	{ position: [3.1, -1.7, -2], scale: 1, color: TERTIARY, kind: 'icosa', opacity: 0.45 },
	{ position: [0.4, 2.8, -3], scale: 1, color: ACCENT, kind: 'knot', opacity: 0.5 },
	{ position: [4.3, 2.3, -4], scale: 0.8, color: ACCENT3, kind: 'torus', opacity: 0.45 },
	{ position: [-4.6, -2.5, -3], scale: 1.2, color: ACCENT4, kind: 'icosa', opacity: 0.4 },
	{ position: [2.5, 3.5, -5], scale: 0.7, color: SECONDARY, kind: 'knot', opacity: 0.5 },
	{ position: [-3.7, 3.2, -4], scale: 0.9, color: TERTIARY, kind: 'sphere', opacity: 0.45 },
	{ position: [4.9, -3.3, -5], scale: 0.6, color: ACCENT, kind: 'sphere', opacity: 0.5 },
	{ position: [-1.9, -3.5, -4], scale: 1.1, color: ACCENT3, kind: 'knot', opacity: 0.45 },
	{ position: [1.9, -2.2, -1.5], scale: 0.55, color: TERTIARY, kind: 'octa', opacity: 0.5 },
	{ position: [-5.2, 0.4, -6], scale: 0.9, color: SECONDARY, kind: 'box', opacity: 0.4 },
	{ position: [0, 4.1, -6], scale: 0.7, color: ACCENT4, kind: 'octa', opacity: 0.45 },
	{ position: [-2.6, -4.4, -5.5], scale: 0.8, color: ACCENT, kind: 'sphere', opacity: 0.5 },
	{ position: [5.4, 0.8, -7], scale: 1.1, color: ACCENT3, kind: 'torus', opacity: 0.4 },

	// Capa media
	{ position: [-6.4, 2.9, -6], scale: 1, color: WARNING, kind: 'cone', opacity: 0.45 },
	{ position: [6.8, -2.6, -6], scale: 0.9, color: SUCCESS, kind: 'cylinder', opacity: 0.4 },
	{ position: [-5.6, -3.4, -5], scale: 1.1, color: SECONDARY, kind: 'dodeca', opacity: 0.45 },
	{ position: [5.9, 3.6, -5], scale: 0.8, color: TERTIARY, kind: 'tetra', opacity: 0.5 },
	{ position: [-7.8, 1.1, -7], scale: 1.2, color: ACCENT4, kind: 'knot', opacity: 0.4, detail: [0.6, 0.18, 60] },
	{ position: [7.4, 4.2, -7], scale: 1, color: ACCENT, kind: 'icosa', opacity: 0.45 },
	{ position: [-3.9, 4.6, -6], scale: 0.6, color: ACCENT3, kind: 'tetra', opacity: 0.5 },
	{ position: [3.4, -4.6, -6], scale: 0.75, color: WARNING, kind: 'octa', opacity: 0.5 },
	{ position: [6.1, -4.9, -7], scale: 0.9, color: SECONDARY, kind: 'cone', opacity: 0.45 },
	{ position: [-6.6, -4.8, -7], scale: 0.7, color: TERTIARY, kind: 'box', opacity: 0.45 },
	{ position: [2.2, 5.2, -6.5], scale: 1.05, color: ACCENT4, kind: 'sphere', opacity: 0.45 },
	{ position: [-2.4, 5.5, -7], scale: 0.8, color: SUCCESS, kind: 'dodeca', opacity: 0.45 },

	// Capa lejana
	{ position: [-8.9, 3.4, -9], scale: 1.4, color: ACCENT3, kind: 'torus', opacity: 0.3, detail: [1.4, 0.3, 40] },
	{ position: [8.8, -3.8, -9], scale: 1.3, color: ACCENT, kind: 'knot', opacity: 0.3, detail: [0.9, 0.2, 70] },
	{ position: [-9.4, -1.6, -8], scale: 1.2, color: SECONDARY, kind: 'icosa', opacity: 0.3 },
	{ position: [9.2, 1.9, -8], scale: 1.5, color: TERTIARY, kind: 'octa', opacity: 0.3 },
	{ position: [-8.2, -4.9, -9], scale: 1.1, color: ACCENT4, kind: 'sphere', opacity: 0.3 },
	{ position: [8.4, 4.8, -9], scale: 1.2, color: WARNING, kind: 'cone', opacity: 0.3 },
	{ position: [0, -6.4, -8], scale: 1.3, color: ACCENT3, kind: 'torus', opacity: 0.3, detail: [1.6, 0.35, 40] },
	{ position: [-4.4, -6.8, -9], scale: 1, color: TERTIARY, kind: 'dodeca', opacity: 0.3 },
	{ position: [4.6, 6.4, -9], scale: 1.1, color: SECONDARY, kind: 'tetra', opacity: 0.3 },
	{ position: [-1.8, 7.1, -9], scale: 0.9, color: ACCENT, kind: 'cylinder', opacity: 0.3 },
	{ position: [6.9, -6.6, -9], scale: 1, color: SUCCESS, kind: 'box', opacity: 0.3 },
	{ position: [-6.8, 6.2, -9], scale: 1.1, color: ACCENT4, kind: 'sphere', opacity: 0.3 },
];

function ShapeGeometry({ spec }: { spec: ShapeSpec }) {
	const [a, b, c] = spec.detail ?? [1, 1, 1];
	switch (spec.kind) {
		case 'torus':
			return <torusGeometry args={[a, a * 0.22, 16, 60]} />;
		case 'icosa':
			return <icosahedronGeometry args={[a, 0]} />;
		case 'knot':
			return <torusKnotGeometry args={[a, a * 0.32, 90, 14]} />;
		case 'sphere':
			return <sphereGeometry args={[a, 24, 24]} />;
		case 'octa':
			return <octahedronGeometry args={[a, 0]} />;
		case 'box':
			return <boxGeometry args={[a, a, a]} />;
		case 'cone':
			return <coneGeometry args={[a, a * 1.6, 24]} />;
		case 'cylinder':
			return <cylinderGeometry args={[a, a, a * 1.8, 24]} />;
		case 'dodeca':
			return <dodecahedronGeometry args={[a, 0]} />;
		case 'tetra':
			return <tetrahedronGeometry args={[a, 0]} />;
	}
}

function Shape({ spec }: { spec: ShapeSpec }) {
	const mesh = useRef<Mesh>(null);

	useFrame((_, delta) => {
		if (!mesh.current) return;
		const spin = spec.spin ?? 0.5;
		mesh.current.rotation.x += delta * (spin * (0.2 + Math.abs(Math.sin(mesh.current.position.x)) * 0.6));
		mesh.current.rotation.y += delta * (spin * (0.28 + Math.abs(Math.cos(mesh.current.position.y)) * 0.6));
	});

	return (
		<Float speed={spec.speed ?? 2} rotationIntensity={0.7} floatIntensity={1.3}>
			<mesh ref={mesh} position={spec.position} scale={spec.scale}>
				<ShapeGeometry spec={spec} />
				<meshStandardMaterial color={spec.color} wireframe transparent opacity={spec.opacity ?? 0.45} />
			</mesh>
		</Float>
	);
}

function Shapes() {
	const group = useRef<Group>(null);

	useFrame((_, delta) => {
		if (!group.current) return;
		group.current.rotation.y += delta * 0.015;
	});

	return (
		<group ref={group}>
			{SHAPES.map((spec, i) => (
				<Shape key={i} spec={spec} />
			))}
		</group>
	);
}

export default function BackgroundScene() {
	return (
		<div
			aria-hidden
			style={{
				position: 'fixed',
				inset: 0,
				zIndex: 0,
				pointerEvents: 'none',
			}}
		>
			<Canvas camera={{ position: [0, 0, 9], fov: 45 }} dpr={[1, 1.5]}>
				<ambientLight intensity={1.1} />
				<pointLight position={[4, 4, 4]} intensity={40} color="#ffffff" />
				<Sparkles count={320} scale={15} size={2.5} speed={0.35} color={SECONDARY} opacity={0.5} />
				<Sparkles count={160} scale={11} size={2} speed={0.25} color="#ffffff" opacity={0.35} />
				<Sparkles count={100} scale={13} size={2.5} speed={0.45} color={TERTIARY} opacity={0.25} />
				<Shapes />
			</Canvas>
		</div>
	);
}
