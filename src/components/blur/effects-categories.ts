import { EFFECTS } from '@/store/blur-store'

export const EFFECTS_CATEGORIES = [
  {
    category: 'wave',
    label: '🌊 Waves',
    items: EFFECTS.filter((e) => e.category === 'wave'),
  },
  {
    category: 'chase',
    label: '💨 Chase',
    items: EFFECTS.filter((e) => e.category === 'chase'),
  },
  {
    category: 'pattern',
    label: '✦ Pattern',
    items: EFFECTS.filter((e) => e.category === 'pattern'),
  },
  {
    category: 'color',
    label: '🎨 Color',
    items: EFFECTS.filter((e) => e.category === 'color'),
  },
  {
    category: 'advanced',
    label: '⚡ Advanced',
    items: EFFECTS.filter((e) => e.category === 'advanced'),
  },
]
