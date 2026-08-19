import { useState } from 'react';
import WindowTiles from '../../../ui/adapters/react/WindowTiles';

const REVEAL_COLOR = '#12667f';

export default function PageReveal({ children }: { children: React.ReactNode }) {
	const [intro, setIntro] = useState(true);

	return (
		<>
			{children}
			{intro && <WindowTiles color={REVEAL_COLOR} mode="reveal" onComplete={() => setIntro(false)} />}
		</>
	);
}
