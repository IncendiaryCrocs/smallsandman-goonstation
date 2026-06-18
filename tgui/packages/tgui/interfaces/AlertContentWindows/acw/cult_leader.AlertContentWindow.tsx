/**
 * @file
 * @copyright 2024
 * @author garash2k
 * @license ISC
 */
import { resource } from '../../../goonstation/cdn';
import { AlertContentWindow } from '../types';

const CultLeaderContentWindow = () => {
  return (
    <div className="traitor-tips">
      <h1 className="center">You are a Cult Leader!</h1>
      <img
        src={resource('images/antagTips/wizard-image.png')}
        className="center"
      />

      <p>1. As a Cult Leader, be evil. (Jack finish this god dammit!)</p>
    </div>
  );
};

export const acw: AlertContentWindow = {
  title: 'The Cultists guide to the dark gods',
  theme: 'wizard',
  component: CultLeaderContentWindow,
};
