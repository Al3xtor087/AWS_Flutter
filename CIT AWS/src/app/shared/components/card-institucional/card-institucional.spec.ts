import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CardInstitucional } from './card-institucional';

describe('CardInstitucional', () => {
  let component: CardInstitucional;
  let fixture: ComponentFixture<CardInstitucional>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [CardInstitucional],
    }).compileComponents();

    fixture = TestBed.createComponent(CardInstitucional);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
