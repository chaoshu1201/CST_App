function TaperAng = FuncTaperAngleGet(ThetaFarfield, DirCoNorm, Taper)
    IndexArr = DirCoNorm >= Taper;
    ThetaArr = [ThetaFarfield;ThetaFarfield;ThetaFarfield];
    ThetaArrTapered = ThetaArr(IndexArr);
    TaperAng = max(abs(ThetaArrTapered),[],'all');
end