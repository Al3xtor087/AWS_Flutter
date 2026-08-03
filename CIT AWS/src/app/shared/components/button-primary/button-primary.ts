import { Component, input, output } from '@angular/core';

@Component({
  selector: 'app-button-primary',
  imports: [],
  templateUrl: './button-primary.html',
  styleUrl: './button-primary.scss',
  host: {
    'class': 'd-block'
  },
  
})
export class ButtonPrimary {
  color = input<string>('primary');
  loading = input<boolean>(false);
  type = input<'button' | 'submit' | 'reset'>('button');
  customClass = input<string>('');
  onClick = output<MouseEvent>();
}
