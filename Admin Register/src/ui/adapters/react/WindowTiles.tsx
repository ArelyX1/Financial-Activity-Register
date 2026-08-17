import { useMemo, useRef } from 'react';
import { motion } from 'motion/react';
import styles from './WindowTiles.module.css';

interface WindowTilesProps {
	color: string;
	mode: 'cover' | 'reveal';
	tile?: number;
	onComplete?: () => void;
}

interface TileSpec {
	x: number;
	y: number;
	rotateX: number;
	rotateY: number;
	rotateZ: number;
	delay: number;
	duration: number;
}

export default function WindowTiles({ color, mode, tile = 48, onComplete }: WindowTilesProps) {
	const done = useRef(0);

	const tiles = useMemo<TileSpec[]>(() => {
		const cols = Math.ceil(window.innerWidth / tile);
		const rows = Math.ceil(window.innerHeight / tile);
		return Array.from({ length: cols * rows }, (_, i) => ({
			x: (i % cols) * tile,
			y: Math.floor(i / cols) * tile,
			rotateX: (Math.random() - 0.5) * 200 + (Math.random() > 0.5 ? 180 : 0),
			rotateY: (Math.random() - 0.5) * 200,
			rotateZ: (Math.random() - 0.5) * 100,
			delay: Math.random() * 0.47,
			duration: 0.23 + Math.random() * 0.27,
		}));
	}, [tile]);

	const handleComplete = () => {
		done.current += 1;
		if (onComplete && done.current >= tiles.length) onComplete();
	};

	return (
		<div className={styles.field}>
			{tiles.map((t, i) => (
				<motion.div
					key={i}
					className={styles.tile}
					style={{
						width: tile,
						height: tile,
						left: t.x,
						top: t.y,
						background: color,
					}}
					initial={
						mode === 'cover'
							? { scale: 0, rotateX: 0, rotateY: 0, rotateZ: 0, opacity: 1 }
							: { scale: 1, opacity: 1 }
					}
					animate={
						mode === 'cover'
							? { scale: 1, rotateX: t.rotateX, rotateY: t.rotateY, rotateZ: t.rotateZ, opacity: 1 }
							: { scale: 0, rotateX: t.rotateX, rotateY: t.rotateY, rotateZ: t.rotateZ, opacity: 0 }
					}
					transition={{ duration: t.duration, delay: t.delay, ease: [0.22, 1, 0.36, 1] }}
					onAnimationComplete={handleComplete}
				/>
			))}
		</div>
	);
}
