const formatNumberOn2Digits = (number) => ("0" + number).slice(-2);

const secondsToTime = (timeInSeconds) => {
  let h = Math.floor(timeInSeconds / 3600);
  let m = Math.floor((timeInSeconds % 3600) / 60);
  let s = Math.floor(timeInSeconds % 3600) % 60;
  let ms = (timeInSeconds % 1).toString().slice(2, 4) || 0;

  h = formatNumberOn2Digits(h);
  m = formatNumberOn2Digits(m);
  s = formatNumberOn2Digits(s);
  ms = formatNumberOn2Digits(ms);

  return { h, m, s, ms };
};

export { secondsToTime };
