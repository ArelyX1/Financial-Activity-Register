import { useMemo, useRef } from 'react';
import { motion } from 'motion/react';
import styles from './Morph.module.css';

interface MorphTilesProps {
	src: string;
	cols: number;
	rows: number;
	width: number;
	height: number;
	onComplete: () => void;
}

interface Tile {
	x: number;
	y: number;
	w: number;
	h: number;
	rotateX: number;
	rotateY: number;
	rotateZ: number;
	duration: number;
	delay: number;
	hue: number;
	blur: boolean;
}

function randSpin() {
	const spins = [0, 1, -1, 2, -2, 3];
	return spins[Math.floor(Math.random() * spins.length)] * 360;
}

export default function MorphTiles({ src, cols, rows, width, height, onComplete }: MorphTilesProps) {
	const done = useRef(0);
	const tiles = useMemo<Tile[]>(() => {
		const tw = width / cols;
		const th = height / rows;
		return Array.from({ length: cols * rows }, (_, i) => {
			const col = i % cols;
			const row = Math.floor(i / cols);
			return {
				x: col * tw,
				y: row * th,
				w: tw,
				h: th,
				rotateX: randSpin() + (Math.random() - 0.5) * 540,
				rotateY: randSpin() + (Math.random() - 0.5) * 540,
				rotateZ: (Math.random() - 0.5) * 720,
				duration: 0.3 + Math.random() * 0.37,
				delay: Math.random() * 0.27,
				hue: Math.random() > 0.5 ? 210 : -150,
				blur: Math.random() > 0.7,
			};
		});
	}, [cols, rows, width, height]);

	const handleComplete = () => {
		done.current += 1;
		if (done.current >= tiles.length) onComplete();
	};

	return (
		<motion.div
			className={styles.field}
			style={{ perspective: 900 }}
			exit={{ opacity: 0, scale: 0.25, transition: { duration: 0.3 } }}
		>
			{tiles.map((tile, i) => (
				<motion.div
					key={i}
					className={`${styles.tile} ${tile.blur ? styles.blur : ''}`}
					style={{
						left: tile.x,
						top: tile.y,
						width: tile.w,
						height: tile.h,
						backgroundImage: `url(${src})`,
						backgroundSize: `${width}px ${height}px`,
						backgroundPosition: `${-tile.x}px ${-tile.y}px`,
					}}
					initial={{ rotateX: 0, rotateY: 0, rotateZ: 0, filter: 'none' }}
					animate={{
						rotateX: tile.rotateX,
						rotateY: tile.rotateY,
						rotateZ: tile.rotateZ,
						filter: ['none', `hue-rotate(${tile.hue}deg) saturate(1.8) contrast(1.2)`, 'none'],
					}}
					transition={{
						duration: tile.duration,
						delay: tile.delay,
						ease: [0.22, 1, 0.36, 1],
						filter: { duration: tile.duration * 0.9, delay: tile.delay },
					}}
					onAnimationComplete={handleComplete}
				/>
			))}
		</motion.div>
	);
}
