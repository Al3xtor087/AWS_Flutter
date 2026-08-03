import { Component, Input, OnChanges, OnInit, SimpleChanges } from '@angular/core';
import { ChartConfiguration } from 'chart.js';
import { BaseChartDirective } from 'ng2-charts';

@Component({
  selector: 'app-grafica-incidencias',
  imports: [BaseChartDirective],
  templateUrl: './grafica-incidencias.html',
  styleUrl: './grafica-incidencias.scss',
})
export class GraficaIncidencias implements OnInit, OnChanges {
  @Input() color: string = '#ffc107';
  @Input() alto: number = 50;
  @Input() datos: number[] = [0, 0, 0, 0, 0];
  @Input() labels: string[] = [];
  @Input() label: string = "";
  

  public lineChartData!: ChartConfiguration['data'];
  public lineChartOptions: ChartConfiguration['options'] = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: { legend: { display: false } },
    scales: { x: { display: false }, y: { display: false } }
  };

  ngOnInit() {
    this.inicializarGrafica();
  }

  ngOnChanges(changes: SimpleChanges) {
    if (changes['datos'] || changes['labels']) {
      this.inicializarGrafica();
    }
  }

  private inicializarGrafica() {
    this.lineChartData = {
      datasets: [{
        data: this.datos,
        label: this.label,
        borderColor: this.color,
        backgroundColor: this.hexToRgba(this.color, 0.2),
        fill: 'origin',
        tension: 0.4,
        pointBackgroundColor: this.color,
        pointBorderColor: this.color,
        pointRadius: 4,
        pointHoverRadius: 6,
        pointHitRadius: 10,
        pointBorderWidth: 1
      }],
      labels: this.labels.length > 0 ? this.labels : ['07:00', '08:00', '09:00', '10:00', '11:00', '12:00', '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00']
    };
  }

  private hexToRgba(hex: string, alpha: number) {
    const r = parseInt(hex.slice(1, 3), 16);
    const g = parseInt(hex.slice(3, 5), 16);
    const b = parseInt(hex.slice(5, 7), 16);
    return `rgba(${r}, ${g}, ${b}, ${alpha})`;
  }
}
