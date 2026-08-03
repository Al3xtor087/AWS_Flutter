import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ButtonPrimary } from './button-primary';

describe('ButtonPrimary', () => {
  let component: ButtonPrimary;
  let fixture: ComponentFixture<ButtonPrimary>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ButtonPrimary],
    }).compileComponents();

    fixture = TestBed.createComponent(ButtonPrimary);
    component = fixture.componentInstance;
    await fixture.whenStable();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
